# Phase-Handoff Gates + PR-on-Completion — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make a workflow phase unfinishable until its artifact is on the specs repo's default branch — producers commit, push, and open a PR; consumers refuse to start until the previous artifact is there.

**Architecture:** One new reference, `references/phase-handoff.md`, owns two entry points: `handoff-to-main` (producer) and `require-on-main` (consumer, a ten-state gate). Eight commands gain producer calls, seven gain consumer calls. `ard-resolution.md` gains an `unmerged` status. Existing rules that J invalidates — the branch-prefix authority, five "never opens a PR" statements, `/create-vi`'s relocation ownership, and sixteen `/ready` never-commits/never-branches claims — are corrected across three editions.

**Tech Stack:** Prompt markdown only — commands, agents, references. **No code, no test framework.** Verification is `grep`/`awk`/`diff`/reading, with all counts whitespace-normalized.

**Spec:** `docs/superpowers/specs/2026-08-14-phase-handoff-gates-design.md` (53 requirements R1–R53, 13 decisions D1–D13, 9 risks).
**Appendix A:** `docs/superpowers/plans/2026-08-14-phase-handoff-gates-appendix-reference.md` — the verbatim body of the new reference. Tasks 1 and 2 write from it.

## Global Constraints

- Ships as dev-workflows **2.52.0** (canonical), **2.52.0** (mgd), **2.22.0** (copilot).
- Branch `iv-gu/phase-handoff-gates` exists in canonical, forked from `main` at `987ce32`, with the spec at `0e3384a`. The mgd and copilot branches do **not** exist yet — Tasks 18 and 19 create them.
- The branch-prefix authority becomes `^(idea|vi|ard|spec|design|ready)/` — six prefixes, up from four.
- Every git call against the specs repo is `git -C "$SPECS_PATH" …`; **never** a `cd`. Every `gh` call names the repo with `-R`.
- Never `push --force`, `branch -D`, `merge`, `rebase`, `reset`, `stash`, `checkout --`, and never delete an `index.lock`.
- **The gate never promotes an optional input to a prerequisite.** Row F (absent) delegates to each command's pre-existing behaviour. An absent input that stops any command except `/design` is a **Critical**.
- `ard-resolution.md`'s `status: none` definition and its no-regression rule must survive **byte-identical**.
- `/create-vi`'s parameter change is a **breaking change** in each CHANGELOG and README.
- mgd is content-verbatim with canonical **except its five identity files** (`.claude-plugin/plugin.json`, `LICENSE`, `README.md`, `CHANGELOG.md`, `references/dependencies.md`) plus root `CLAUDE.md` and `.claude-plugin/marketplace.json`. Verify empirically at port time; **never blind-`cp`**.
- **Never `cp` into copilot.** Its four dialect rules: `subagent_type:` → `agent_type:`; `${CLAUDE_PLUGIN_ROOT}/references/X.md` → `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/X.md`; the `§2.1 Sonnet chain` → its own detection chain; command names in **colon form** (`idea:`) not slash form (`/idea`).
- **Assertion style:** prefer "zero occurrences of the stale pattern, ≥1 of the new" over "exactly N occurrences". Absolute counts go stale when the plan is amended; relational assertions do not. Where a count is asserted, re-derive it against the tree being verified — never copy one from another task.
- Prose in plugin files is **never hard-wrapped** (`references/prose-formatting.md`): one paragraph is one unbroken line.

---

## File structure

**Created**

| Path | Responsibility |
|---|---|
| `plugins/dev-workflows/references/phase-handoff.md` | Both entry points, the ten-state gate, the delegation table, the outcome/stop contracts. The single place any of this is stated. |
| `.../ihudak-copilot-plugins/dev-workflows/skills/_shared/phase-handoff.md` | The copilot-dialect equivalent, hand-written. |

**Modified — shared references**

| Path | Change |
|---|---|
| `references/specs-repo-git.md` | six-prefix authority (4 sites), `:20` scoping, §3.6 rationale rewrite |
| `references/ard-resolution.md` | `unmerged` status, caller list `:4-5`, no-regression preserved verbatim |
| `references/finish-and-handoff.md` | `:6`, `:43`, `:74` — capability, not policy |
| `references/next-phase-offer.md` | next-step wording includes the merge step |

**Modified — commands** (`plugins/dev-workflows/commands/`)

`idea.md`, `create-vi.md`, `update-vi.md`, `create-ard.md`, `specify.md`, `design.md`, `implement.md`, `epics.md`, `ready.md`, `document.md`

**Modified — identity and catalog**

`CLAUDE.md` (root), `plugins/dev-workflows/README.md`, `plugins/dev-workflows/CHANGELOG.md`, `plugins/dev-workflows/.claude-plugin/plugin.json`; the mgd and copilot equivalents; copilot's `.github/plugin/marketplace.json` and `.github/copilot-instructions.md`.

---

## Task 1: The new reference — producer half

**Files:**
- Create: `plugins/dev-workflows/references/phase-handoff.md`
- Read: `docs/superpowers/plans/2026-08-14-phase-handoff-gates-appendix-reference.md`

**Interfaces:**
- Produces: the file `references/phase-handoff.md` with sections §0–§2, §4, §5 and the literal marker line `<!-- Task 2 inserts §3 here -->`. Task 2 replaces that marker. Every later task cites section numbers from this file — `§2` for the producer entry point, `§4.1` for its outcome line, `§4.3` for the consent choice, `§5` for the caller contract.
- Produces the caller-input names Tasks 6–13 pass: `prefix`, `feature_folder`, `deliverable_paths`, `title`, `body_facts`.

- [ ] **Step 1: Read Appendix A**

Read `docs/superpowers/plans/2026-08-14-phase-handoff-gates-appendix-reference.md` in full. Its first fenced block is the body to write. Do not paraphrase it.

- [ ] **Step 2: Write the file**

Create `plugins/dev-workflows/references/phase-handoff.md` containing exactly the contents of Appendix A's **first** fenced block — from `# Phase handoff — Shared Reference` through the end of §5 — including the literal line `<!-- Task 2 inserts §3 here -->`.

Do **not** include Appendix A's own prose (its title, its "This appendix is…" paragraph, or the `---` separators). Only the fenced body.

- [ ] **Step 3: Assert the structure**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# every section present
for s in "^# Phase handoff" "^## 1\. Hard rules" "^## 2\. \`handoff-to-main\`" "^### 2\.2 Branch resolution" "^### 2\.6 Open the pull request" "^### 2\.9 Caller-supplied inputs" "^## 4\. Reporting" "^### 4\.3 The consent choice" "^## 5\. Caller contract"; do
  printf "%-42s %s\n" "$s" "$(grep -cE "$s" references/phase-handoff.md)"
done
# the Task 2 marker exists exactly once
grep -c "Task 2 inserts" references/phase-handoff.md
```

Expected: every section count is `1`; the marker count is `1`.

- [ ] **Step 4: Assert the three deliberate divergences are stated**

The whole reason this is a separate file is that it contradicts `specs-repo-git.md` on three points. If a reader cannot find all three, a future "consistency fix" will break the contract.

```bash
grep -cE "fatal by design" references/phase-handoff.md          # expect 1
grep -cE "Co-Authored-By\` trailer IS carried" references/phase-handoff.md  # expect 1
grep -cE "runs only behind a user choice" references/phase-handoff.md       # expect 1
```

- [ ] **Step 5: Assert the verified commands landed unaltered**

These were executed against a real specs repo before the plan was written. A substituted equivalent is a defect.

Use fixed-string matching (`grep -F`) for anything containing regex metacharacters — an escaped-regex assertion that fails to compile silently returns 0 and proves nothing.

Only the commands §2 actually contains. `gh pr list -R`, `cat-file -e`, and `diff --quiet` live in §3 and are **Task 2's** to assert — asserting them here would either fail or pressure you into importing Task 2's content early.

```bash
grep -Fc 'sed -E' references/phase-handoff.md                    # expect >=1
grep -Fc 'gh pr create -R' references/phase-handoff.md           # expect >=1
grep -Fc 'status --porcelain --untracked-files=all' references/phase-handoff.md  # expect >=1
grep -Fc 'merge-base --is-ancestor' references/phase-handoff.md  # expect >=1
grep -Fc 'rev-parse --verify --quiet' references/phase-handoff.md # expect >=1
```

**Prove the assertion can fail** before trusting it — the point of this step is that a check you cannot show failing proves nothing:

```bash
grep -Fc 'gh pr merge' references/phase-handoff.md   # expect 0 — D2 forbids plugin-side merging
```

Every count above must be `>=1` and the last must be `0`. No `|| true` anywhere: a suppressed failure is a passing check that verified nothing.

- [ ] **Step 6: Assert no hard-wrapped prose**

```bash
awk 'length($0)>0 && $0 !~ /^[|# ]/ && $0 !~ /^ *[-0-9]/ && length($0)<70 {c++} END{print c+0}' references/phase-handoff.md
```

Read any hits: a short line is fine for a heading, list item, table row, or code; it is a defect only if it is a paragraph broken mid-sentence.

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/phase-handoff.md
git commit -m "feat(dev-workflows): phase-handoff.md — the handoff-to-main producer entry point

Closes R1-R6, R10 (producer half). New reference rather than a section of
specs-repo-git.md because it contradicts that file on three points, each
stated in its §1: require-on-main is fatal by design, the Co-Authored-By
trailer is carried, and the entry point runs only behind a user choice.

§2.2's collision rule is not defensive coding: _readiness.md is
overwritten every /ready run and gh pr create fails on an already-merged
branch, while force-push and branch -D are both forbidden."
```

---

## Task 2: The new reference — consumer half and the reachability trace

**Files:**
- Modify: `plugins/dev-workflows/references/phase-handoff.md` (replace the Task 2 marker)
- Create: `docs/superpowers/plans/2026-08-14-gate-reachability.md`

**Interfaces:**
- Consumes: the file from Task 1 and its marker line.
- Produces: §3 with the ten-state table and §3.7's return contract — `on_main: pass | pass_amending | absent | unmanaged`, `stopped`, `branch`, `pr`, `degraded`. Tasks 7–13 branch on exactly these values.

- [ ] **Step 1: Insert §3**

Replace the line `<!-- Task 2 inserts §3 here -->` in `references/phase-handoff.md` with the contents of Appendix A's **second** fenced block (the one headed `## 3. \`require-on-main\``), verbatim.

- [ ] **Step 2: Assert all ten states are present, in order**

Extract the first table cell rather than matching an alternation — a regex alternation containing both `C` and `C′` is order-dependent and `.` does not reliably match a multibyte `′`.

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
awk -F'|' '/^\|/ && $2 !~ /^ *-+ *$/ && $2 !~ /#/ {gsub(/ /,"",$2); printf "%s ", $2}' \
  <(awk '/^### 3\.3 The state table/,/^### 3\.4/' references/phase-handoff.md); echo
```

Expected output, in this exact order: `H I A B C′ C D E F G`.

Prove this assertion can fail: run the same command against the §3.4 table instead (`/^### 3\.4/,/^### 3\.5/`) and confirm it prints command names, not state letters. A check that returns the same thing regardless of input is not a check.

If C precedes C′, that is a defect: offering a switch git would refuse is worse than naming the blocker.

- [ ] **Step 3: Assert row B's protection is stated as branch ownership**

Row B is the one state whose absence causes data loss.

```bash
grep -cE "must not be folded into C" references/phase-handoff.md      # expect 1
grep -cE "branch ownership, never whether the file differs" references/phase-handoff.md  # expect 1
grep -cE "discard the in-progress design" references/phase-handoff.md # expect 1
```

- [ ] **Step 4: Assert §3.4's delegation table covers all seven callers**

```bash
awk '/^### 3\.4 Row F delegates/,/^### 3\.5/' references/phase-handoff.md \
  | grep -cE '^\| `/'
```

Expected: `7`. Then read the table and confirm the `/create-vi` row contains the sentence `**\`/idea\` is not a prerequisite.**` — that is Risk 8's anchor.

- [ ] **Step 4b: Assert §3's verified primitives landed unaltered**

These three strings exist only in §3, so they are this task's to assert — Task 1 could not, and its own Step 5 was corrected to stop trying. Each was executed against a real specs repo before the plan was written; a substituted equivalent is a defect.

```bash
grep -Fc 'cat-file -e' references/phase-handoff.md               # expect >=1
grep -Fc 'diff --quiet' references/phase-handoff.md              # expect >=1
grep -Fc 'gh pr list -R' references/phase-handoff.md             # expect >=1
grep -Fc '2>/dev/null' references/phase-handoff.md               # expect >=1
```

The `2>/dev/null` matters on its own: without it, `cat-file -e` writes `fatal: path … does not exist` to stderr on every absent artifact, and that leaks into the run's output.

Prove these can fail: `grep -Fc 'hash-object' references/phase-handoff.md` — expect **0**. Blob equality deliberately uses `diff --quiet` instead, because `hash-object` on the working file misses a staged-only change.

- [ ] **Step 5: Write the reachability trace (Risk 1's mitigation)**

Create `docs/superpowers/plans/2026-08-14-gate-reachability.md` with one row per state. Each row must name a **concrete repository condition** that reaches it, not a restatement of the row's own predicate. Use exactly this table, filled in:

| State | Concrete reaching condition | Observable outcome |
|---|---|---|
| H | `SPECS_PATH` unset, or set to a directory with no `.git` | returns `unmanaged`; caller unchanged |
| I | `git -C "$S" switch --detach origin/main` before the run | stop + the G0 notice |
| A | repo on `main`, freshly pulled, artifact committed and merged | pass |
| B | `/design` run 2 on `design/<KEY>-<slug>`, `specification.md` locally amended by run 1 | `pass_amending`, reported, **no switch offered** |
| C | repo on an unrelated named branch (G2 shape) that also carries an older `specification.md` | repair offer, re-test once |
| C′ | same as C, plus an uncommitted edit to a file the switch would overwrite | stop naming the files |
| D | artifact committed on `spec/<KEY>-<slug>`, pushed, PR open, `main` without it | stop naming PR #n |
| E | same as D but the PR closed unmerged, or never opened | stop naming the branch |
| F | a fresh VI folder with no `idea.md` anywhere | returns `absent`; the caller's ladder continues |
| G | `git -C "$S" update-ref -d refs/remotes/origin/main` (or a clone with no remote-tracking ref) | stop — cannot verify |

A state whose reaching condition you cannot write down is a defect in §3.3, not a gap in this table. Report it rather than inventing a condition.

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/phase-handoff.md docs/superpowers/plans/2026-08-14-gate-reachability.md
git commit -m "feat(dev-workflows): phase-handoff.md — require-on-main and the ten-state gate

Closes R7-R10, R53 (reference side). Primitives verified against a real
specs repo before writing: cat-file -e against origin/<default> for the
on-main test, and diff --quiet against the ref for blob equality (which
also catches a staged-only change that hash-object on the working file
would miss).

Row order H I A B C' C D E F G is deliberate. Row B must not be folded
into C: /design amends specification.md on its own branch, so on a resume
the worktree legitimately differs, and row C would offer a switch that
discards the in-progress design.

Row F delegates rather than stopping. Every gated input except /design's
specification.md is optional today, and a stop on absence would silently
make /idea, /create-ard and VI-level /specify mandatory.

Risk 1's mitigation ships as a reachability trace naming the concrete
repository condition for each of the ten states."
```

---

## Task 3: `ard-resolution.md` — the `unmerged` status

**Files:**
- Modify: `plugins/dev-workflows/references/ard-resolution.md` (66 lines)

**Interfaces:**
- Consumes: `require-on-main`'s §3.7 return contract from Task 2.
- Produces: `status: found | none | unmerged` plus, for `unmerged`, the fields `branch` and `pr`. Tasks 8, 10, 11, 12, 13 consume exactly these.

- [ ] **Step 1: Capture the two lines that must survive byte-identical**

R50 requires the optionality statements unchanged. Capture them now so Step 5 can prove it.

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -n "the common case" references/ard-resolution.md > /tmp/ard-none-before.txt
awk '/^## No-regression rule/,/^## Deviation-record/' references/ard-resolution.md > /tmp/ard-noregress-before.txt
cat /tmp/ard-none-before.txt /tmp/ard-noregress-before.txt
```

- [ ] **Step 2: Add `unmerged` to the output schema**

Locate the schema:

```bash
grep -n "status: found | none" references/ard-resolution.md
```

Change that line to `status: found | none | unmerged`, and immediately below the existing `status: none` sentence add these two paragraphs (each one unbroken line):

> `status: unmerged` when an ARD file resolves but is **not on the specs repo's default branch** — verified via `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3 (`require-on-main`), which returns the carrying `branch` and any open `pr`. Both are passed through to the caller.

> **`unmerged` is reachable only when an ARD file resolves.** An absent ARD is `none`, unchanged — see the no-regression rule below. This status does not make `/create-ard` a prerequisite for anything.

- [ ] **Step 3: Extend the no-regression section without touching its existing text**

Append to the `## No-regression rule (central)` section, after its existing paragraph, one new paragraph:

> A caller that gets `status: unmerged` **stops**, naming the branch and any open pull request, except `/ready` — which is a read-only verifier and records it as a readiness finding capping the verdict at `PARTIAL`. The distinction matters: reporting a phase as complete while its ARD sits unmerged is exactly the claim `/ready` exists to check.

- [ ] **Step 4: Fix the stale caller list (R51)**

```bash
grep -n "Cited by" references/ard-resolution.md
```

That header names four callers while the file's own `## Consumers` section lists five. Add `/ready` to the header list. Confirm the body already has it:

```bash
grep -c '^- `/ready`' references/ard-resolution.md   # expect 1
```

- [ ] **Step 5: Prove the optionality text is byte-identical (Risk 8)**

```bash
grep -n "the common case" references/ard-resolution.md > /tmp/ard-none-after.txt
awk '/^## No-regression rule/,/^## Deviation-record/' references/ard-resolution.md \
  | grep -v "status: unmerged" > /tmp/ard-noregress-after.txt
diff /tmp/ard-none-before.txt /tmp/ard-none-after.txt && echo "none-definition: IDENTICAL"
diff <(grep -v '^$' /tmp/ard-noregress-before.txt) <(grep -v '^$' /tmp/ard-noregress-after.txt) \
  && echo "no-regression rule: IDENTICAL (modulo the appended paragraph)"
```

Both must print their `IDENTICAL` line. If the first diff is non-empty, the `none` definition was disturbed — revert and redo Step 2.

- [ ] **Step 6: Assert the three statuses and the five callers**

```bash
grep -c "found | none | unmerged" references/ard-resolution.md   # expect 1
awk '/^## Consumers/,0' references/ard-resolution.md | grep -cE '^- `/'  # expect 5
grep -oE '/(design|implement|specify|epics|ready)' <(grep "Cited by" -A1 references/ard-resolution.md) | sort -u | wc -l  # expect 5
```

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/ard-resolution.md
git commit -m "feat(dev-workflows): ard-resolution.md — the unmerged status

Closes R29, R50, R51. status: found | none | unmerged. unmerged is
reachable only when an ARD file resolves, so the ARD stays optional: the
status-none definition and the no-regression rule are proven
byte-identical by diff, not asserted.

Also corrects the header's caller list, which named four callers while
the file's own Consumers section listed five — /ready was missing from
the header only."
```

---

## Task 4: `specs-repo-git.md` — six-prefix authority, scoping, §3.6

**Files:**
- Modify: `plugins/dev-workflows/references/specs-repo-git.md` (419 lines)

**Interfaces:**
- Consumes: nothing.
- Produces: the six-prefix authority every later task relies on, and a §3.6 that survives with a new rationale.

- [ ] **Step 1: Locate every prefix site**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -nE 'vi\|ard\|spec\|design|vi/ ard/ spec/ design/' references/specs-repo-git.md
```

Four hits: §1 rule 3, §2.2, §4.1, and §5's G2 notice. Read each before editing.

- [ ] **Step 2: Extend all four to six prefixes**

- The two regex forms become `^(idea|vi|ard|spec|design|ready)/`.
- The `vi|ard|spec|design/*` form in §4.1 becomes `idea|vi|ard|spec|design|ready/*`.
- The G2 notice's prose list `(vi/ ard/ spec/ design/)` becomes `(idea/ vi/ ard/ spec/ design/ ready/)`.

- [ ] **Step 3: Confirm branch-key extraction needs no change**

```bash
grep -n "Branch key extraction" -A3 references/specs-repo-git.md
```

It strips a known prefix then takes the leading `[A-Z][A-Z0-9_]*-[0-9]+` token. Extend the prefix list it names to six, but do **not** change the token regex — `/idea` and `/ready` branches carry ordinary Jira keys.

- [ ] **Step 4: Scope `:20` (R32)**

```bash
grep -n "Nothing here opens a pull request" references/specs-repo-git.md
```

Replace that sentence with (one unbroken line):

> Neither entry point here opens a pull request: `specs-preflight` and `commit-artifacts` are prompt-free bookkeeping steps, and opening a pull request is outward-facing. Deliverable handoff — including `gh pr create` where the host supports it — lives in `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2.6, behind that reference's consent choice. `git push` here is git-protocol, already sanctioned by `finish-and-handoff.md` §3.

- [ ] **Step 5: Rewrite §3.6's rationale, keeping B3 (R33)**

Read §3.6 in full first (`awk '/^### 3\.6/,/^### 3\.7/' references/specs-repo-git.md`). Keep its heading, keep the "do not simplify it away" warning, and keep the B3 row in §3.5 untouched. Replace the *reason*:

- **Remove** the claim that B3 exists to prevent `/create-ard`'s silent fallback to a stale Jira export. That bug is now caught loudly by `require-on-main` rows D/E.
- **Add**: B3 now exists for two reasons. First, **same-phase resume** — `require-on-main` row B is a *pass* precisely when the worktree copy differs because this run's own branch amends it; if the preflight switched away from that branch, `/design`'s in-progress amendments to `specification.md` would be left behind and row B would never be reachable. Second, **`/ready`'s explicit checkout** — the user may choose to proceed on the current checkout, and switching off it while the report claims that checkout was read would make the report false.
- **Add** the cross-reference: the failure §3.6 used to defend against is now `phase-handoff.md` §3.3 rows D and E, which stop rather than proceeding silently.
- **Keep** the closing observation that stacking is the honest representation of an ARD depending on its VI.

- [ ] **Step 6: Assert**

```bash
# zero stale four-prefix forms
grep -cE 'vi\|ard\|spec\|design\)/' references/specs-repo-git.md         # expect 0
grep -cE '\(vi/ ard/ spec/ design/\)' references/specs-repo-git.md       # expect 0
# six-prefix form present
grep -cE '\^\(idea\|vi\|ard\|spec\|design\|ready\)/' references/specs-repo-git.md  # expect >=2
# :20 rescoped, phase-handoff cross-referenced
grep -c "Nothing here opens a pull request" references/specs-repo-git.md # expect 0
grep -c "phase-handoff.md" references/specs-repo-git.md                  # expect >=2
# B3 survives, stale rationale gone
grep -c "^| B3 |" references/specs-repo-git.md                           # expect 1
grep -ci "stale Jira export" references/specs-repo-git.md                # expect 0
grep -c "row B" references/specs-repo-git.md                             # expect >=1
```

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/specs-repo-git.md
git commit -m "feat(dev-workflows): specs-repo-git.md — six prefixes, rescoped :20, §3.6 rewritten

Closes R31, R32, R33. Prefix authority gains idea/ and ready/ at all four
sites. :20 no longer reads as a plugin-wide ban on pull requests — it is
now scoped to this file's own two prompt-free entry points and points at
phase-handoff.md §2.6 for deliverables.

§3.6 keeps B3 and its do-not-simplify warning but replaces the reason.
The spec's decisions record predicted §3.6 would dissolve; it does not.
B3 is what makes require-on-main row B reachable, and without it the
preflight would switch away from the branch holding /design's in-progress
amendments to specification.md. The bug §3.6 originally defended against
— /create-ard silently architecting from a stale Jira export — is now
caught by rows D/E, which stop."
```

---

## Task 5: The statements J invalidates in other references

**Files:**
- Modify: `plugins/dev-workflows/references/finish-and-handoff.md:6,43,74`
- Modify: `plugins/dev-workflows/commands/document.md:1080`
- Modify: `plugins/dev-workflows/README.md:217`
- Modify: `plugins/dev-workflows/references/next-phase-offer.md`

**Interfaces:**
- Consumes: `phase-handoff.md` §2.6's capability argument from Task 1.
- Produces: nothing other tasks consume.

- [ ] **Step 1: Locate all five PR-claim sites**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -rniE "never opens (a|the) (pull request|PR)|never creates? a PR|Never call a PR REST|it never opens the PR via an API" \
  references/finish-and-handoff.md commands/document.md README.md
```

- [ ] **Step 2: Reword each to state the capability, not a ban**

`/document`'s **behaviour does not change** — it still writes a draft and never opens the PR. Only the stated reason changes, because "never" read as policy and the real reason is that its repos are Bitbucket-hosted with no CLI.

- `finish-and-handoff.md:6` — replace "The plugin NEVER creates a PR via any REST API." with: *"This flow does not open the pull request itself: docs repos here are Bitbucket-hosted, and Bitbucket offers no CLI that can create one. Where a host does — the GitHub-hosted specs repo — the plugin opens it via `gh`; see `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2.6."*
- `finish-and-handoff.md:43` — "Never force-push. Never call a PR REST API." becomes *"Never force-push. Never call a REST API over HTTPS; `gh` wraps the API and is permitted where a host provides it."*
- `finish-and-handoff.md:74` — "The plugin never opens the PR itself." becomes *"For a Bitbucket-hosted docs repo the plugin cannot open the pull request — there is no CLI for it — so it writes the draft and the user opens it. This is a host capability limit, not a policy: on a host with a CLI the plugin does open it (`phase-handoff.md` §2.6)."*
- `document.md:1080` — replace the trailing "The plugin never opens the PR itself." with the same capability sentence, shortened to one clause.
- `README.md:217` — "(it never opens the PR via an API)" becomes *"(it writes a draft rather than opening the PR — Bitbucket has no CLI that can; the GitHub-hosted specs repo does get a real PR, via `references/phase-handoff.md`)"*.

- [ ] **Step 3: Add the merge step to `next-phase-offer.md` (R41)**

Read the file, then add one paragraph to the contract (one unbroken line):

> **A next-step offer that names a downstream command must also name the merge.** The downstream command executes `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) and stops while this phase's pull request is open, so an offer that reads "next: `/dev-workflows:create-ard <KEY>`" without "once the pull request is merged" sends the user into a stop they were not warned about.

- [ ] **Step 4: Assert**

```bash
grep -rncE "never opens (a|the) (pull request|PR)|never creates? a PR|Never call a PR REST|it never opens the PR via an API" \
  references/finish-and-handoff.md commands/document.md README.md    # every count expect 0
grep -rc "phase-handoff.md" references/finish-and-handoff.md commands/document.md README.md references/next-phase-offer.md
grep -ci "once the pull request is merged\|once it is merged" references/next-phase-offer.md   # expect >=1
# /document behaviour unchanged: it still writes a draft and offers a command for the user to run
grep -c "gh pr create" references/finish-and-handoff.md              # expect >=1 (still the user's command)
grep -ci "opt-in" references/finish-and-handoff.md                   # expect >=1 (push still opt-in)
```

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/finish-and-handoff.md plugins/dev-workflows/commands/document.md plugins/dev-workflows/README.md plugins/dev-workflows/references/next-phase-offer.md
git commit -m "fix(dev-workflows): the no-PR rule was a capability limit, not a policy

Closes R34, R35, R41. Five statements said the plugin never opens a pull
request. The reason was always that docs and code repos here are
Bitbucket-hosted and Bitbucket has no CLI that can create one — not a
decision anyone made. Restated as capability, with a pointer to
phase-handoff.md §2.6 for the GitHub-hosted specs repo.

/document's behaviour is unchanged: it still writes a draft and still
offers a gh command the user may run.

next-phase-offer.md now requires an offer naming a downstream command to
also name the merge, since that command will stop while this phase's pull
request is open."
```

---

## Task 6: `/idea` — relocation and the `vi_disposition` handoff

**Files:**
- Modify: `plugins/dev-workflows/commands/idea.md` (361 lines) — frontmatter `:3`, `:13`, Phase 4 `:191-256`, Phase 5 `:260-287`

**Interfaces:**
- Consumes: `phase-handoff.md` §2 and §4.3 (Task 1); the existing `vi_disposition` (`rewrite` | `new`) computed at `idea.md:228`.
- Produces: `idea.md` at `$SPECS_PATH/specifications/<KEY>-<slug>/idea.md` on branch `idea/<KEY>-<slug>`, which Task 7's `/create-vi` gate resolves.

- [ ] **Step 1: Correct the frontmatter description (R37)**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -n "no specs deliverable" commands/idea.md
```

Replace the clause "no Jira, no code, no specs deliverable — the only `$SPECS_PATH` writes are the run's own session artifacts, committed by `commit-artifacts`" with: *"no Jira, no code; on a completed handoff it relocates `idea.md` into `$SPECS_PATH/specifications/<KEY>-<slug>/` and opens a pull request for it (`references/phase-handoff.md` §2), and its session artifacts are committed by `commit-artifacts`"*.

- [ ] **Step 2: Correct `:13`**

`grep -n "relocates it under" commands/idea.md` — it currently says `/create-vi` relocates the idea. Replace with: *"`/idea` relocates it under `$SPECS_PATH` itself once a Jira key exists (Phase 5); `/create-vi <KEY>` then finds it there and does not move it."*

- [ ] **Step 3: Rewrite Phase 5's three branches**

Replace Phase 5's three status/disposition bullets with these, keeping the surrounding prose (the prior-art report, the code-grounding report, and the never-auto-invoke sentence) intact:

- **`vi_disposition: rewrite`** — the key is already known from the `vi` source. Relocate `idea.md` to `$SPECS_PATH/specifications/<KEY>-<slug>/idea.md` (resolve the folder by key-number, tolerating a human-adjusted slug), then execute `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2) with `prefix: idea`, `deliverable_paths` = the relocated file, `title: <KEY> Refine idea for <summary>`. **No human round trip** — the key exists. Then report the §4.1 outcome line.
- **`vi_disposition: new`, `status: refined`** — ask: `choices: ["Create the Jira workitem now and give me the key — I'll complete the handoff (Recommended)", "Leave it in the vault — I'll hand it off later", "Other… (describe)"]`. On a key matching `^[A-Z][A-Z0-9_]*-\d+$`, relocate and run `handoff-to-main` as above. On the second choice, report plainly: *"Not handed off — `idea.md` stays at `<path>`. `/create-vi <KEY>` will not find it; use the out-of-contract form `/dev-workflows:create-vi <KEY> @<path>`."*
- **`status: draft`** (N open `[NEEDS CLARIFICATION]`) — **never hand off**, and do not ask. By the governing principle the phase is not finished. Report the N open items and offer `--deep`, or the out-of-contract `@<path>` route. State explicitly that no branch or pull request was created.

- [ ] **Step 4: Assert the three branches and the draft prohibition**

```bash
awk '/^## Phase 5 — Handoff/,/^### Context hygiene/' commands/idea.md > /tmp/idea-p5.txt
grep -c "handoff-to-main" /tmp/idea-p5.txt          # expect >=2 (rewrite + new/refined)
grep -c "prefix: idea" /tmp/idea-p5.txt             # expect >=1
grep -ci "never hand off" /tmp/idea-p5.txt          # expect >=1
grep -c "phase-handoff.md" /tmp/idea-p5.txt         # expect >=1
# the draft branch must NOT reach a handoff: no handoff-to-main after the draft bullet
awk '/status: .?draft/,0' /tmp/idea-p5.txt | grep -c "handoff-to-main"   # expect 0
```

The last assertion is the one that matters: a `draft` idea reaching `handoff-to-main` would hand off an unfinished phase.

- [ ] **Step 5: Assert the stale claims are gone**

```bash
grep -c "no specs deliverable" commands/idea.md              # expect 0
grep -c '`/create-vi` relocates it' commands/idea.md         # expect 0
```

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/idea.md
git commit -m "feat(dev-workflows): /idea completes its own handoff

Closes R11, R12, R37. Phase 5 now relocates idea.md into
\$SPECS_PATH/specifications/<KEY>-<slug>/ and opens a pull request on
idea/<KEY>-<slug>, conditioned on the vi_disposition it already computes.

rewrite needs no round trip — the key is known. new+refined offers to take
a key. draft NEVER hands off and is not even asked: by the governing
principle a phase with open clarifications is not finished, so there is
nothing to hand over.

Also corrects the frontmatter's 'no specs deliverable' claim, which this
change makes false, and :13's statement that /create-vi does the
relocation."
```

---

## Task 7: `/create-vi` — gate the idea, drop the relocation

**Files:**
- Modify: `plugins/dev-workflows/commands/create-vi.md` (266 lines) — Phase 0 `:28-32`, `:59`, Phase 5 `:193-201`

**Interfaces:**
- Consumes: `require-on-main` §3.7 (`pass`/`pass_amending`/`absent`/`unmanaged`), `handoff-to-main` §2, §4.3.
- Produces: the VI on `vi/<KEY>-<slug>`, which Task 8's `/create-ard` gate resolves.

- [ ] **Step 1: Rewrite the Phase 0 idea ladder**

Read `create-vi.md:28-32`. Replace the ladder with, in this order:

1. **In-contract** — `specifications/<KEY>-<slug>/idea.md`, resolved from `<KEY>`. Execute `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) against it. On `pass`/`pass_amending`, use it and **do not relocate** — `/idea` already did. On a stopping state, stop per §4.4. On `absent`, fall through to rung 2.
2. **Out-of-contract `@path`** — read the idea where it sits, **never move it**, and do not gate it. Report once: *"out-of-contract: reading `<path>` in place; it will not be relocated or gated."*
3. Same-session `/idea` output (confirm with the user) — out-of-contract, as rung 2.
4. Discover under `$VAULT_PATH/Projects` — out-of-contract, as rung 2.
5. Prompt for a path, or — last resort — proceed with **no idea** and grill the VI from scratch.

Rung 5 is load-bearing: **`/idea` is not a prerequisite for `/create-vi`.** An `absent` in-contract idea must reach rung 5, never a stop.

- [ ] **Step 2: Delete the relocation step**

`grep -n "Relocate \`idea.md\`" commands/create-vi.md` — remove that whole numbered step. Keep the `derived_from` provenance recording, sourcing the original path from the idea's own frontmatter `sources` instead of from the move.

- [ ] **Step 3: Correct Phase 5's write list**

`grep -n "the relocated" commands/create-vi.md` — "Write the feature folder: `<KEY>_<slug>.md` + the relocated `idea.md`" becomes "Write the feature folder: `<KEY>_<slug>.md`. The in-contract `idea.md` is already there, committed by `/idea`; an out-of-contract idea stays where it is."

- [ ] **Step 4: Replace the handoff with `handoff-to-main`**

Replace the prose after the consent choice ("On the first choice, in the specs repo…") with a citation: execute `handoff-to-main` (§2) with `prefix: vi`, `feature_folder` as resolved, `deliverable_paths` = the VI file, `title: <KEY> Add Value Increment — <summary>`; emit its §4.1 line in the Final report. Present §4.3's choice array verbatim — including the reworded second option.

- [ ] **Step 5: Assert**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -c "require-on-main" commands/create-vi.md        # expect >=1
grep -c "handoff-to-main" commands/create-vi.md        # expect >=1
grep -c "the relocated" commands/create-vi.md          # expect 0
grep -c "Relocate \`idea.md\`" commands/create-vi.md   # expect 0
# Risk 8: absent must reach the grill-from-scratch rung, not a stop
grep -ci "grill the VI from scratch" commands/create-vi.md   # expect >=1
grep -ci "not a prerequisite" commands/create-vi.md          # expect >=1
# the consent choice is verbatim, including the consequence clause
grep -c "the next phase will stop until this is on main" commands/create-vi.md  # expect 1
```

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/create-vi.md
git commit -m "feat(dev-workflows)!: /create-vi <KEY> derives the idea; @<path> is out-of-contract

BREAKING CHANGE: /create-vi no longer relocates idea.md. /idea owns that
now. /create-vi <KEY> derives specifications/<KEY>-<slug>/idea.md and
gates it on main; /create-vi <KEY> @<path> reads the idea where it sits,
does not move it, and is not gated.

Closes R13, R21, and the create-vi half of R36.

An absent in-contract idea falls through to the existing ladder and can
still end at 'grill the VI from scratch' — /idea does not become a
prerequisite. That path is asserted, not assumed."
```

---

## Task 8: `/create-ard` and `/specify` — gates and handoffs

**Files:**
- Modify: `plugins/dev-workflows/commands/create-ard.md` (190 lines) — Phase 0 `:22-33`, Phase 2 `:64-79`, Phase 6 `:142-143`
- Modify: `plugins/dev-workflows/commands/specify.md` (548 lines) — Phase 0, Phase 2.5 `:265-270`, Phase 7 `:409-418`

**Interfaces:**
- Consumes: `require-on-main` §3.7; `ard-resolution.md`'s `unmerged` (Task 3); `handoff-to-main` §2.
- Produces: the ARD on `ard/<VI|EPIC>-<slug>` and `specification.md` on `spec/<EPIC|VI>-<slug>` — Tasks 10 and 12 gate on these.

- [ ] **Step 1: `/create-ard` — gate the VI, report the fallback**

In Phase 0 (after `$SPECS_PATH` resolves and the preflight runs), execute `require-on-main` against `specifications/<VI>-<vslug>/<VI>_<vslug>.md`. Then:

- `pass`/`pass_amending` → read the authored VI as today.
- a stopping state → stop per §4.4.
- `absent` → the existing `jira-reader` fallback applies, **but report it**: *"No authored VI on `<default>` for `<VI>` — architecting from the Jira export at `<path>`. If a VI exists on a branch, this run would have stopped; it does not, so none does."* This is the silent fallback `specs-repo-git.md` §3.6 used to warn about, now visible.
- `unmanaged` → behave exactly as before this feature.

- [ ] **Step 2: `/create-ard` — gate the inherited VI-level ARD**

On an Epic-level run, the VI-level ARD is inherited. Where Phase 2 resolves it, honour `ard-resolution.md`'s status: `unmerged` → stop naming the branch and any PR; `none` → unchanged.

- [ ] **Step 3: `/create-ard` — Phase 6 handoff**

Replace Phase 6's inline git prose with `handoff-to-main` (§2): `prefix: ard`, `deliverable_paths` = the ARD file(s), `title: <KEY> Add architecture requirements document`. Present §4.3's array verbatim.

- [ ] **Step 4: `/specify` — gate the VI and the ARD**

In Phase 0, execute `require-on-main` against the VI file, with the same four outcomes as Step 1 (an `absent` VI keeps `/specify`'s existing Jira-export behaviour and is reported). In Phase 2.5, honour `unmerged` from `ard-resolution.md` with a stop.

- [ ] **Step 5: `/specify` — Phase 7 handoff**

Replace Phase 7's inline git prose with `handoff-to-main` (§2): `prefix: spec`, `deliverable_paths` = `specification.md`, `_session.md`, `_glossary.md`, and the rendered `.html`; `title: <KEY> Add specification`. Keep the branch-name derivation rules (`spec/<EPIC>-<eslug>` for per-Epic or stand-alone-Epic, `spec/<VI>-<vslug>` for a broad VI-level spec) — pass the result as `prefix` + `feature_folder`. Keep the "Merged-to-main = ready for the dev-team handover" sentence; it is now enforced rather than aspirational.

- [ ] **Step 6: Assert both**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for f in commands/create-ard.md commands/specify.md; do
  printf "%s require=%s handoff=%s unmerged=%s consent=%s\n" "$f" \
    "$(grep -c require-on-main $f)" "$(grep -c handoff-to-main $f)" \
    "$(grep -c 'unmerged' $f)" \
    "$(grep -c 'the next phase will stop until this is on main' $f)"
done
```

Expected for each: `require>=1 handoff>=1 unmerged>=1 consent=1`.

```bash
# Risk 8: an absent VI must not stop either command
grep -ci "architecting from the Jira export" commands/create-ard.md   # expect >=1
# ordering (R30): the gate precedes the first scan dispatch
grep -n "require-on-main" commands/create-ard.md | head -1
grep -n "code-scanner" commands/create-ard.md | head -1
```

The gate's line number must be smaller than the first `code-scanner` line. Record both numbers.

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/create-ard.md plugins/dev-workflows/commands/specify.md
git commit -m "feat(dev-workflows): /create-ard and /specify gate their inputs and hand off via PR

Closes R15, R16, R22, R23. Both gate the VI and the applicable ARD, and
both replace inline git prose with handoff-to-main.

/create-ard's absent-VI fallback to the Jira export is now reported
rather than silent. That silent fallback is the exact bug
specs-repo-git.md §3.6 was written to warn about, and it is now decided:
a VI on a branch stops the run, so reaching the fallback proves no
authored VI exists.

The gate is placed before the first code-scanner dispatch, with both line
numbers recorded — a gate that fires after a fan-out has already spent
what it was meant to save."
```

---

## Task 9: `/update-vi` — producer only, deliberately not gated

**Files:**
- Modify: `plugins/dev-workflows/commands/update-vi.md` (144 lines) — Phase 0 step 5 `:24`, Phase 5 `:90-95`

**Interfaces:**
- Consumes: `handoff-to-main` §2, §4.3.
- Produces: the canonical + archived VI revisions on `vi/<KEY>-<slug>`.

- [ ] **Step 1: Add the handoff**

In Phase 5, after writing the canonical and archived revisions, execute `handoff-to-main` (§2): `prefix: vi`, `deliverable_paths` = both revision files, `title: <KEY> Update Value Increment`. Present §4.3's array verbatim. Emit the §4.1 line in the Final report.

- [ ] **Step 2: Record why the secondary reads are NOT gated (D13, R47)**

At Phase 0 step 5 ("Secondary grounding (read-only)"), add one unbroken line:

> These reads are **not** gated by `require-on-main`: `/update-vi`'s authoritative base is the Jira import, and Phase 2 already rules that the import wins where a frozen draft disagrees. Gating advisory grounding would block a legitimate VI refresh because an unrelated ARD sits on a branch. Where a discovered `*_ARD.md` or `specification.md` is **not** on the specs repo's default branch, say so in the Phase 1 confirmation beside the existing divergence notice — the user should know the grounding is unapproved, not be stopped by it.

- [ ] **Step 3: Assert**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -c "handoff-to-main" commands/update-vi.md     # expect >=1
grep -c "require-on-main" commands/update-vi.md     # expect 0 — deliberately ungated
grep -ci "not.*gated" commands/update-vi.md         # expect >=1
grep -c "the next phase will stop until this is on main" commands/update-vi.md  # expect 1
```

The `require-on-main` count of **0** is the assertion, not an omission. If a reviewer flags it, point at D13.

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/update-vi.md
git commit -m "feat(dev-workflows): /update-vi hands off via PR; its grounding stays ungated

Closes R14, R47. /update-vi is a producer — the canonical and archived
revisions now reach main via handoff-to-main on vi/<KEY>-<slug>.

It is deliberately NOT a consumer. Its authoritative base is the Jira
import, and Phase 2 already rules the import wins over a frozen draft, so
gating advisory grounding would block a legitimate refresh because an
unrelated ARD sits on a branch. An off-main grounding artifact is
reported in the Phase 1 confirmation instead. The zero require-on-main
count in this file is the assertion, not an oversight."
```

---

## Task 10: `/design` — both gate sites and the handoff

**Files:**
- Modify: `plugins/dev-workflows/commands/design.md` (444 lines) — Phase 0 step 3 `:45-57`, step 4's picker `:64-84`, Phase 2.5 `:170-175`, Phase 7 `:303-319`

**Interfaces:**
- Consumes: `require-on-main` §3.7 — in particular `pass_amending` (row B); `ard-resolution.md`'s `unmerged`; `handoff-to-main` §2.
- Produces: `design.md` + the amended `specification.md` on `design/<EPIC|VI>-<slug>`, which Task 11's `/implement` gate resolves.

- [ ] **Step 1: Replace step 3's broken gate (finding I3, site 1)**

Read `design.md:45-57`. The prose says "confirm the spec is on main" but the test is a worktree file-existence check, which passes on any branch carrying the file. Replace the check with `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) against the resolved `specification.md`, and map the outcomes:

- `pass` → proceed.
- **`pass_amending`** (row B) → proceed, printing the row-B report line. This is the resume case: `/design` itself amends `specification.md`, so on a re-run the worktree copy legitimately differs. **Do not offer to switch branches here** — that would discard this run's own in-progress amendments.
- `absent` → keep today's stop, wording unchanged: `spec not handed off — run /dev-workflows:specify for this item and merge it to the specs repo main first.`
- `unmanaged` → behave as before this feature.
- any other stopping state → stop per §4.4.

- [ ] **Step 2: Fix the Epic picker (finding I3, site 2)**

Read `design.md:64-84`. The picker enumerates "Epic subfolders each with a `specification.md` on main" using a worktree test — so it lists branch-only Epics as designable. Replace the enumeration predicate with the ref test:

```
git -C "$SPECS_PATH" cat-file -e "origin/<default>:specifications/<VI>-<vslug>/<EPIC>-<eslug>/specification.md" 2>/dev/null
```

An Epic whose `specification.md` is **not** on the default branch is excluded from the actionable set and counted in the existing "excluded count" report, with the reason distinguished: *"N Epic(s) excluded — no specification.md; M excluded — specification.md not yet merged to `<default>`."* Fixing only step 3 and leaving the picker would let a user select an Epic the step-3 gate then stops on.

- [ ] **Step 3: Gate the ARD in Phase 2.5**

Honour `ard-resolution.md`'s `unmerged` with a stop naming the branch and any PR. `none` stays unchanged.

- [ ] **Step 4: Phase 7 handoff**

Replace the inline git prose with `handoff-to-main` (§2): `prefix: design`, `deliverable_paths` = `design.md`, the amended `specification.md`, `_design-session.md`, `_design-glossary.md`; `title: <KEY> Add engineering design`. Keep the unresolved-`- [ ]` refusal gate ahead of it, and keep "Merged-to-main = ready for `/implement`". Present §4.3's array verbatim.

- [ ] **Step 5: Assert both I3 sites are closed (Risk 4)**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -c "require-on-main" commands/design.md            # expect >=1
grep -c "cat-file -e" commands/design.md                # expect >=1 (the picker's ref test)
grep -c "pass_amending" commands/design.md              # expect >=1
grep -ci "not yet merged to" commands/design.md         # expect >=1 (picker exclusion reason)
grep -c "handoff-to-main" commands/design.md            # expect >=1
grep -c "the next phase will stop until this is on main" commands/design.md  # expect 1
# today's absent-case stop text survives verbatim
grep -c "spec not handed off" commands/design.md        # expect 1
```

- [ ] **Step 6: Prove row B does not offer a switch (Risk 4's mitigation)**

Read the step-3 outcome mapping and confirm, in writing, that the `pass_amending` branch contains **no** switch/pull offer and no reference to §3.3 row C. Record the line numbers of the `pass_amending` branch and of any `switch` mention in the same phase; if they interleave, that is the data-loss defect.

```bash
awk '/^3\. \*\*Map onto the specs repo/,/^4\. \*\*Granularity/' commands/design.md \
  | grep -nE "pass_amending|switch|pull --ff-only"
```

Expected: `pass_amending` appears; `switch` and `pull --ff-only` do **not** appear in that range.

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/design.md
git commit -m "fix(dev-workflows): /design's on-main gate now actually tests main — both sites

Closes R17, R24, R25. Finding I3 had two sites, not the one the review
named. Step 3 claimed to confirm the spec was on main via a worktree
file-existence test, which passes on any branch carrying the file. The
Epic picker at :67-68 had the same defect at enumeration scope, so it
listed branch-only Epics as designable — a user could select an Epic the
step-3 gate would then stop on.

Both now test origin/<default> by ref. The picker distinguishes 'no
specification.md' from 'not yet merged' in its excluded count.

Row B (pass_amending) proceeds without offering a branch switch, and that
absence is asserted: /design amends specification.md on its own branch,
so a switch offer on a resume would discard the in-progress design."
```

---

## Task 11: `/implement` — gate, late handoff, scoped claim

**Files:**
- Modify: `plugins/dev-workflows/commands/implement.md` — Phase 0 `:60-110`, Phase 2 `:234`, Phase 3B step 7.5 `:488`, Phase 4/5 boundary, `:718`

**Interfaces:**
- Consumes: `require-on-main` §3.7; `ard-resolution.md`'s `unmerged`; `handoff-to-main` §2.
- Produces: the escalation notes on `spec/…` or `design/…`.

- [ ] **Step 1: Gate the in-scope specs in Phase 0**

Where Phase 0 resolves a `specification.md`/`design.md`, execute `require-on-main` against each **in-scope** file. `/implement` runs standing in a **code** repo, so every stop text must name the specs repo explicitly — `$SPECS_PATH`, not "the repo".

- `absent` → **only an in-scope spec is gated.** A direct-prompt run resolves none and is entirely unaffected. Do not stop.
- `unmanaged` → unchanged behaviour.
- stopping states → stop per §4.4, with `$SPECS_PATH` named.

- [ ] **Step 2: Gate the ARD in Phase 2**

Honour `unmerged` from `ard-resolution.md` with a stop. `none` (including direct mode) unchanged.

- [ ] **Step 3: Keep 7.5 writing where it is; hand off late**

Do **not** call `handoff-to-main` from step 7.5 — it sits inside Phase 3B, before the tests run, and committing there would interrupt the run mid-review. Add to step 7.5: *"The notes are written here and handed off later — see the escalation handoff after Phase 4."*

Then add a new step **after Phase 4 (post-implementation maintenance) and before the emitter tail** (feedback → follow-ups → cost → `resume.md` → `commit-artifacts`). It executes `handoff-to-main` (§2) when step 7.5 wrote any note: `prefix` = `spec` if only `specification.md` was annotated, otherwise `design`; `deliverable_paths` = the annotated file(s); `title: <KEY> Record spec/design conformance findings from /implement`. Present §4.3's array verbatim. When 7.5 wrote nothing, this step is a silent no-op.

Placement is load-bearing, not stylistic: `implement.md:718`'s claim is scoped to Phase 7, and a `handoff-to-main` call inside Phase 6 or 7 would falsify it.

- [ ] **Step 4: Scope the `:718` claim (R52)**

```bash
grep -n "NEVER commits the deliverable" commands/implement.md
```

`:719` already defines "the deliverable" as the implementation on the Pre-Phase 3 branch, so the claim is true — but read plainly it says `/implement` commits nothing at all. Append to its parenthetical: *"; the spec/design conformance notes from step 7.5 are handed off separately, before this phase, via `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2"*.

Leave `:669` alone — it is about follow-up files in the follow-up phase and stays true.

- [ ] **Step 5: Assert**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -c "require-on-main" commands/implement.md   # expect >=1
grep -c "handoff-to-main" commands/implement.md   # expect >=1
grep -c "the next phase will stop until this is on main" commands/implement.md  # expect 1
# R52: :718's claim is scoped
grep -c "handed off separately" commands/implement.md   # expect 1
# the handoff is NOT inside Phase 6 or Phase 7
H=$(grep -n "handoff-to-main" commands/implement.md | tail -1 | cut -d: -f1)
P6=$(grep -n "^## Phase 6" commands/implement.md | cut -d: -f1)
echo "handoff line=$H  Phase6 line=$P6  (handoff must be < Phase6)"
```

The final comparison is Risk-driven: if the handoff line is greater than the Phase 6 line, `:718`'s claim is falsified and this is a defect.

```bash
# Risk 8: a direct-prompt run must not be gated
grep -ci "in-scope" commands/implement.md          # expect >=1
grep -ci "direct.prompt run resolves none\|direct mode" commands/implement.md  # expect >=1
```

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/implement.md
git commit -m "feat(dev-workflows): /implement gates its specs and hands off its escalation notes

Closes R18, R26, R52. Phase 7.5's conformance notes were written into
\$SPECS_PATH and committed by nothing: commit-artifacts stages only the
dev-workflows/** bookkeeping paths, so the notes sat dirty forever and
tripped the G1 advisory on every later run of every command. Worse, G1's
notice calls them 'yours' and says nothing is lost — so nobody acted on
them and ordinary git hygiene could delete them silently.

They are still written in 7.5 but handed off after Phase 4 and before the
emitter tail. The placement is asserted by line-number comparison because
implement.md:718's claim is Phase-7-scoped and a call inside Phase 6 or 7
would falsify it. :718 also gains a clause naming the separate handoff;
:669 is untouched, being about follow-up files in the follow-up phase.

Only an in-scope spec is gated — a direct-prompt run resolves none and is
unaffected. Stop texts name \$SPECS_PATH, since /implement stands in a
code repo."
```

---

## Task 12: `/epics` — the conditional gate

**Files:**
- Modify: `plugins/dev-workflows/commands/epics.md` — the ARD resolution `:155-158` and the VI-spec detection `:174-197`

**Interfaces:**
- Consumes: `require-on-main` §3.7; `ard-resolution.md`'s `unmerged`.
- Produces: nothing other tasks consume. `/epics` remains a non-producer and keeps its never-branches claims.

- [ ] **Step 1: Gate the VI-level `specification.md` conditionally**

At the detection step that currently sets `vi_spec_present`, insert `require-on-main` against the resolved `<VI-dir>/specification.md`:

- `absent` → `vi_spec_present: false` and **the existing silent skip, unchanged**. The Jira-export-only path must keep working: **VI-level `/specify` stays optional.**
- `pass`/`pass_amending` → `vi_spec_present: true`, proceed as today.
- `unmanaged` → unchanged behaviour.
- `unmerged`/rows D/E → **stop** per §4.4, because drafting Epics against a weaker basis than the one about to land means re-doing them.

- [ ] **Step 2: Gate the ARD**

Honour `unmerged` from `ard-resolution.md` with a stop; `none` unchanged.

- [ ] **Step 3: Confirm `/epics` stays a non-producer**

`/epics` writes its drafts to the vault, never to `$SPECS_PATH`. It gains **no** `handoff-to-main` call and its never-branches claims stay true.

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -c "handoff-to-main" commands/epics.md        # expect 0
grep -c "never branches" commands/epics.md         # expect >=2 — still true
```

- [ ] **Step 4: Assert**

```bash
grep -c "require-on-main" commands/epics.md            # expect >=1
grep -c "vi_spec_present: false" commands/epics.md     # expect >=1 — the skip survives
grep -ci "remains optional\|stays optional" commands/epics.md  # expect >=1
# ordering (R30): gate before the code-scanner fan-out
G=$(grep -n "require-on-main" commands/epics.md | head -1 | cut -d: -f1)
S=$(grep -n "code-scanner" commands/epics.md | head -1 | cut -d: -f1)
echo "gate=$G scanner=$S (gate must be < scanner)"
```

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/epics.md
git commit -m "feat(dev-workflows): /epics gates a VI-level spec that exists but is unmerged

Closes R27. The gate is conditional by design: an absent VI-level
specification.md keeps vi_spec_present: false and the existing silent
skip, so the Jira-export-only path works exactly as before and VI-level
/specify stays optional. Only a spec that EXISTS off main stops the run,
because drafting Epics from a weaker basis than the one about to land
means re-doing them.

/epics gains no handoff-to-main — it writes drafts to the vault, not
\$SPECS_PATH — and its never-branches claims stay true. Both facts are
asserted so a later reader does not 'complete' the pattern."
```

---

## Task 13: `/ready` — gate as a finding, and become a producer

**Files:**
- Modify: `plugins/dev-workflows/commands/ready.md` (~560 lines) — frontmatter `:3`, the intro block `:16-21`, `:47`, Phase 1 inventory `:80-115`, Phase 2.5 `:174-189`, Phase 5 `:259-370`, `:378`, `:470`, `:501`, `:544-558`, plus `:110-112`

**Interfaces:**
- Consumes: `require-on-main` §3.7; `ard-resolution.md`'s `unmerged`; `handoff-to-main` §2.
- Produces: `_readiness.md` on `ready/<KEY>-<slug>`.

- [ ] **Step 1: Gate as a finding, never a stop (R28)**

In the Phase 1 artifact inventory, execute `require-on-main` against each of the ARD, `specification.md`, and `design.md` that the inventory finds. `/ready` **never stops** on any state — its job is to report readiness:

- `pass`/`pass_amending` → the artifact counts as handed off.
- rows D/E (`exists, not on main`) → a readiness finding: *"`<artifact>` is authored on `<branch>` but not on `<default>`" + the PR number when one is open* — and the verdict is **capped at `PARTIAL`**.
- `absent` → the artifact is recorded as missing in the coverage roll-up, exactly as today.
- `unmanaged` → unchanged behaviour.

Reporting a phase as complete while its artifact is off main is the specific claim `/ready` exists to check, so the cap is the point of this task.

- [ ] **Step 2: Add the handoff for `_readiness.md`**

After Phase 5 writes `_readiness.md`, execute `handoff-to-main` (§2): `prefix: ready`, `deliverable_paths` = the `_readiness.md` path, `title: <KEY> Record readiness verdict — <SUPPORTED|PARTIAL|NOT-SUPPORTED>`. Present §4.3's array verbatim. Because `_readiness.md` is **overwritten** on every run, the §2.2 collision rule will often substitute a `-2`/`-3` branch name — the §4.1 line reports that.

- [ ] **Step 3: Narrow the eleven never-commits claims (R38)**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -nE "never commits|never auto-commit|git is the user" commands/ready.md
```

Ten sites in `ready.md` (`:3, :18, :343, :363, :364, :378, :470, :501, :544, :558`) plus `CLAUDE.md:250` (Task 15). **Narrow, do not delete** — `:558`'s "NEVER **auto**-commit" stays true because the commit is behind §4.3's consent choice. Each becomes a form of: *"never commits `_readiness.md` automatically — only via the `phase-handoff.md` §4.3 consent choice"*. Where a site says "git is the user's responsibility", replace with *"the commit is offered, never automatic; declining leaves `_readiness.md` uncommitted"*.

- [ ] **Step 4: Correct the five never-branches claims (R49)**

```bash
grep -nE "never branch|creates none" commands/ready.md
```

Five sites (`:17, :110, :112, :545, :555`). `:555` is a hard invariant. Each becomes: `/ready` creates `ready/<KEY>-<slug>` **only** on the §4.3 consent choice; `specs-preflight` still creates none.

`:17` and `:18` are adjacent lines of one prose block carrying *both* claim families — rewrite that block once, covering both.

- [ ] **Step 5: Correct the frontmatter and `:47`**

`:3`'s "Read-only — never sets Jira status, never commits the deliverable" becomes *"Read-only against the artifacts — never sets Jira status; its own `_readiness.md` snapshot is committed only via the consent choice"*. Update `:47` to mention the handoff.

- [ ] **Step 6: Assert**

```bash
grep -c "require-on-main" commands/ready.md            # expect >=1
grep -c "handoff-to-main" commands/ready.md            # expect >=1
grep -c "the next phase will stop until this is on main" commands/ready.md  # expect 1
# R28: /ready must never stop on the gate
awk '/^## Phase 1 /,/^## Phase 1\.5/' commands/ready.md | grep -ci "stop"   # read every hit
grep -ci "capped at .PARTIAL\|caps the verdict" commands/ready.md   # expect >=1
# R38/R49: no bare claim survives
grep -cE "never commits the deliverable\.|never branches \(still true" commands/ready.md  # expect 0
grep -ci "only via the .*consent choice\|only on the consent choice" commands/ready.md   # expect >=3
```

Read every `stop` hit inside Phase 1: if any is the gate stopping the run, that violates R28 and is a Critical.

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/ready.md
git commit -m "feat(dev-workflows): /ready gates as a finding and hands off _readiness.md

Closes R19, R28, R38, R49. /ready is the one consumer that must never
stop: its job is to report readiness, so an artifact that exists off main
becomes a finding that caps the verdict at PARTIAL. Reporting a phase
complete while its artifact is unmerged is the exact claim /ready exists
to check.

It also becomes a producer. _readiness.md was written into \$SPECS_PATH
and committed by nothing, so it sat dirty and tripped G1 forever, and
because it looked like the user's own stray edit nobody knew to act on it.

Sixteen claim sites corrected: eleven never-commits narrowed to 'never
automatically' — which stays true, since the commit is behind the consent
choice — and five never-branches, including the hard invariant at :555.
:17 and :18 are one prose block carrying both families and were rewritten
once. The never-branches family was found by reading that block, not by
the grep that found the rest."
```

---

## Task 14: Cross-cutting sweeps — consent verbatim, gate ordering, dead-gate proof

**Files:**
- Create: `docs/superpowers/plans/2026-08-14-cross-cutting-checks.md`
- Modify: any file the sweeps find non-conforming

**Interfaces:**
- Consumes: Tasks 6–13.
- Produces: three recorded proof tables the Task 20 verification record cites.

- [ ] **Step 1: R20 — the consent choice is verbatim in all eight producers**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for f in idea create-vi update-vi create-ard specify design implement ready; do
  printf "%-12s %s\n" "$f" "$(grep -c 'Branch + commit + push + open PR to main (Recommended)' commands/$f.md)"
done
for f in idea create-vi update-vi create-ard specify design implement ready; do
  printf "%-12s consequence=%s\n" "$f" "$(grep -c "the next phase will stop until this is on main" commands/$f.md)"
done
```

Every count must be `1`. A producer missing the consequence clause is a producer whose user is never told that declining has a downstream cost.

- [ ] **Step 2: R30 — every gate precedes the first expensive operation**

Record a numeric pair per consumer. Seven rows, no assurances:

```bash
for f in create-vi create-ard specify design implement epics ready; do
  G=$(grep -n "require-on-main" commands/$f.md | head -1 | cut -d: -f1)
  X=$(grep -nE "code-scanner|docs-grounder|jira-reader|Grill|grill" commands/$f.md | head -1 | cut -d: -f1)
  printf "%-12s gate=%-5s first-expensive=%-5s ok=%s\n" "$f" "${G:-NONE}" "${X:-NONE}" \
    "$( [ -n "$G" ] && [ -n "$X" ] && [ "$G" -lt "$X" ] && echo YES || echo CHECK )"
done
```

Every row must be `YES`, or `CHECK` with a written justification (for example, the first match is a mention in a phase list rather than a dispatch). Do not accept `CHECK` without reading the surrounding lines.

- [ ] **Step 3: Risk 2 — prove `unmerged` is not a dead gate**

For each of the five `ard-resolution.md` callers, quote **two** lines: the one that receives the status and the one that acts on it. A caller with a receiving line and no acting line is a dead gate — the exact shape that shipped five times in sub-project B2 and that grep alone never catches.

```bash
for f in specify design implement epics ready; do
  echo "=== /$f ==="
  grep -n "unmerged" commands/$f.md
done
```

Record, per caller: the receiving line number, the acting line number, and the action (stop / finding). Five pairs, or R29 is not met.

- [ ] **Step 4: Risk 8 — prove no optional input became a prerequisite**

One row per line of `phase-handoff.md` §3.4's table. For each, name the file and line where the `absent` case reaches the pre-existing behaviour:

| Caller | Input | `absent` reaches | Proof (file:line) |
|---|---|---|---|
| `/create-vi` | `idea.md` | the idea ladder, ending at grill-from-scratch | |
| `/create-ard` | the VI | the reported `jira-reader` fallback | |
| five callers | the ARD | `status: none` + the no-regression rule | |
| `/epics` | VI-level spec | `vi_spec_present: false` silent skip | |
| `/implement` | spec/design | in-scope only; direct mode unaffected | |
| `/design` | `specification.md` | today's stop, wording unchanged | |
| `/ready` | ARD/spec/design | missing in the coverage roll-up | |

Fill every Proof cell. An empty cell means the delegation is unverified. **An absent input that stops any command except `/design` is a Critical** — report it, do not fix it silently.

- [ ] **Step 5: Write the checks file and commit**

```bash
cd /workspace/ihudak-claude-plugins
git add docs/superpowers/plans/2026-08-14-cross-cutting-checks.md plugins/dev-workflows/commands/
git commit -m "test(dev-workflows): cross-cutting proofs — consent, ordering, dead gate, optionality

Three recorded proof tables rather than three assurances.

R20: the consent choice and its consequence clause counted in all eight
producers. R30: a numeric gate-line/first-expensive-line pair per
consumer, since a gate that fires after a code-scanner fan-out has already
spent what it was meant to save. Risk 2: for each of the five
ard-resolution callers, the line that RECEIVES unmerged and the line that
ACTS on it — a receiving line alone is the dead-gate shape that shipped
five times in sub-project B2 and that grep never catches.

Risk 8: one row per §3.4 delegation, each naming the file:line where the
absent case reaches the pre-existing behaviour. An absent input stopping
anywhere but /design is a Critical."
```

---

## Task 15: canonical `CLAUDE.md` and plugin `README.md`

**Files:**
- Modify: `CLAUDE.md` (root) — `:123`, `:147`, `:250`, `:267`, the workflow map `:140-190`, the invariant blocks
- Modify: `plugins/dev-workflows/README.md` — `:17`, `:96`, `:348`, the reference list, the command table

**Interfaces:**
- Consumes: every prior task.
- Produces: nothing other tasks consume, but Tasks 18–19 mirror these into the other editions.

- [ ] **Step 1: Add the `phase-handoff.md` source-truth paragraph (R40)**

In `CLAUDE.md`'s source-truth section (beside the `specs-repo-git.md` paragraph at `:123`), add one unbroken line describing `references/phase-handoff.md`: the two entry points, the six-prefix authority, the ten-state gate, the row-F delegation rule, the three deliberate divergences from `specs-repo-git.md`, and the list of eight producers and seven consumers.

- [ ] **Step 2: Update the workflow map (R39)**

Add a `handoff-to-main` terminal edge to each of the eight producers' map lines, and a `require-on-main` leading edge to each of the seven consumers'. `/idea`'s line gains `→ relocate idea.md → handoff-to-main`. `/epics` keeps its no-branch note.

- [ ] **Step 3: Update the four claim lines**

- `:123` — six prefixes; note that deliverables live in `phase-handoff.md`.
- `:147` — remove "relocate idea.md" from `/create-vi`'s line; add it to `/idea`'s.
- `:250` — narrow `/ready`'s never-commits claim per Task 13.
- `:267` — six prefixes.

- [ ] **Step 4: Update the invariant blocks**

The `/idea`, `/create-vi`, `/ready`, VI-creation-flow, and specs-repo-git invariant lists each gain or lose a bullet. Add one new invariant to the VI-creation-flow block: *"A phase is not finished until its artifact is on the specs repo's default branch — every producer offers branch + commit + push + PR, and every consumer executes `require-on-main` before expensive work; an absent optional input still delegates to the command's pre-existing behaviour and never becomes a prerequisite."*

- [ ] **Step 5: Update the README (R42)**

- `:17` — `/create-vi`'s row: the new grammar (`<KEY>` in-contract and gated; `@<path>` out-of-contract and ungated), and no relocation.
- `:96` — the PM role row: `/idea` relocates, not `/create-vi`.
- `:348` — six prefixes in the `specs-repo-git.md` description.
- `:217` — already done in Task 5; assert it stayed fixed.
- Add a `references/phase-handoff.md` entry to the reference list.
- `/ready`'s and `/idea`'s command-table rows: the handoff.

- [ ] **Step 6: Assert**

```bash
cd /workspace/ihudak-claude-plugins
grep -c "phase-handoff.md" CLAUDE.md plugins/dev-workflows/README.md    # both >=1
grep -cE 'vi\|ard\|spec\|design\)/' CLAUDE.md plugins/dev-workflows/README.md   # both 0
grep -cE 'idea\|vi\|ard\|spec\|design\|ready' CLAUDE.md plugins/dev-workflows/README.md  # both >=1
grep -c "relocate idea.md" CLAUDE.md                     # expect >=1, on /idea's line
awk '/^\/create-vi /' CLAUDE.md | grep -c "relocate"     # expect 0
grep -ci "never becomes a prerequisite" CLAUDE.md         # expect >=1
```

- [ ] **Step 7: Commit**

```bash
git add CLAUDE.md plugins/dev-workflows/README.md
git commit -m "docs(dev-workflows): CLAUDE.md and README reflect the phase-handoff gates

Closes R39, R40, R42. New source-truth paragraph for
references/phase-handoff.md; workflow-map edges for eight producers and
seven consumers; six-prefix authority at both sites; relocation moved from
/create-vi's line to /idea's; /ready's never-commits claim narrowed.

The new VI-creation-flow invariant states the delegation rule explicitly,
because 'a phase must be on main' invites a future reader to make every
gated input mandatory."
```

---

## Task 16: canonical version and CHANGELOG

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `plugins/dev-workflows/CHANGELOG.md`
- Modify: `.claude-plugin/marketplace.json` if it carries a version

**Interfaces:** Consumes Tasks 1–15. Produces the version string Tasks 18–19 mirror.

- [ ] **Step 1: Bump to 2.52.0**

```bash
cd /workspace/ihudak-claude-plugins
grep -n '"version"' plugins/dev-workflows/.claude-plugin/plugin.json
grep -n "version" .claude-plugin/marketplace.json | head -5
```

Set `2.52.0`. If `marketplace.json` carries no version, leave it — record that it does not, so Task 19 does not assume symmetry with copilot's catalog.

- [ ] **Step 2: Write the CHANGELOG entry (R43)**

Add a `## 2.52.0` section at the top, following the file's existing shape. It must contain a **`### Breaking changes`** subsection first:

> **`/create-vi` no longer relocates `idea.md`.** `/idea` now owns relocation and hands the idea off itself. `/dev-workflows:create-vi <KEY>` derives the idea from `specifications/<KEY>-<slug>/idea.md` and requires it on the specs repo's default branch. `/dev-workflows:create-vi <KEY> @<path>` is explicitly out-of-contract: it reads the idea where it sits, does not move it, and is not gated. A run that previously passed `@<path>` for a vault idea keeps working; a run that relied on `/create-vi` moving the file must now let `/idea` do it.

Then the feature sections: the new reference and its two entry points; the eight producers; the seven consumers and the delegation rule; `ard-resolution.md`'s `unmerged`; the two new branch prefixes; the I3 fix at both sites; the `/implement` and `/ready` dirty-file defects; and the reworded no-PR statements.

- [ ] **Step 3: Assert**

```bash
grep -c '"version": "2.52.0"' plugins/dev-workflows/.claude-plugin/plugin.json   # expect 1
grep -c "^## 2.52.0" plugins/dev-workflows/CHANGELOG.md                          # expect 1
awk '/^## 2\.52\.0/,/^## 2\.51/' plugins/dev-workflows/CHANGELOG.md | grep -c "Breaking changes"  # expect 1
# every claim in the entry must be true of the tree — no changelog entry for work that did not land
awk '/^## 2\.52\.0/,/^## 2\.51/' plugins/dev-workflows/CHANGELOG.md | grep -oE '`[a-z-]+\.md`' | sort -u
```

Read that path list and confirm each file exists and was actually changed on this branch:

```bash
git diff --name-only main...HEAD -- plugins/dev-workflows/
```

A CHANGELOG line naming a file this branch did not touch is the "changelog claims a fix that never happened" defect from the last round.

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/.claude-plugin/plugin.json plugins/dev-workflows/CHANGELOG.md .claude-plugin/marketplace.json
git commit -m "chore(dev-workflows): 2.52.0 — phase-handoff gates + PR-on-completion

Breaking: /create-vi no longer relocates idea.md; /idea owns it.
/create-vi <KEY> derives and gates the idea, @<path> is out-of-contract.

Every file path named in the entry was cross-checked against
git diff --name-only main...HEAD. Last round shipped a CHANGELOG claiming
a fix that never landed; this check is why."
```

---

## Task 17: canonical residue sweep — all ten rows, checked-and-correct

**Files:**
- Create: `docs/superpowers/plans/2026-08-14-residue-sweep.md`
- Modify: whatever the sweep finds

**Interfaces:** Consumes Tasks 1–16. Produces the sweep table Task 20 cites and Tasks 18–19 re-run per edition.

- [ ] **Step 1: Sweep each of the spec §7 rows**

Run every command and record the result — **including the rows that were already correct**. A sweep that reports only fixes cannot be told from a sample, which is why the last round's review named 3 stale lines where an exhaustive sweep found 6 of 34.

```bash
cd /workspace/ihudak-claude-plugins
echo "=== 1. four-prefix authority (expect 0 everywhere) ==="
# `design)/` is the escaped-pipe-agnostic anchor: the stale form ends `design)/`, the
# six-prefix form ends `ready)/`. A pipe-based pattern silently misses the §3.3 G2 row,
# whose pipes are backslash-escaped for markdown — that blind spot hid a real site.
grep -rnF 'design)/' --include=*.md plugins/ CLAUDE.md | grep -v CHANGELOG || echo CLEAN
grep -rnF '(vi/ ard/ spec/ design/' --include=*.md plugins/ CLAUDE.md | grep -v CHANGELOG || echo CLEAN
# prove both anchors can fail:
printf 'probe ^(vi|ard|spec|design)/ and (vi/ ard/ spec/ design/)\n' > /tmp/anchor-probe.md
grep -cF 'design)/' /tmp/anchor-probe.md; grep -cF '(vi/ ard/ spec/ design/' /tmp/anchor-probe.md; rm -f /tmp/anchor-probe.md
echo "=== 2. never-opens-a-PR family (expect 0) ==="
grep -rnicE "never opens (a|the) (pull request|PR)|never creates? a PR|Never call a PR REST|never opens the PR via an API" --include=*.md plugins/ CLAUDE.md | grep -v ':0$' || echo CLEAN
echo "=== 3. /create-vi relocates idea.md (expect 0 outside CHANGELOG history) ==="
grep -rniE "relocat" --include=*.md plugins/ CLAUDE.md | grep -viE "/rename|CHANGELOG|cost-emission|session-hygiene|design-format|specs-repo-git.md:.*cost-emission"
echo "=== 4. /idea no-specs-deliverable (expect 0) ==="
grep -rnc "no specs deliverable" --include=*.md plugins/ CLAUDE.md | grep -v ':0$' || echo CLEAN
echo "=== 5-6. /ready never-commits + never-branches (read every hit) ==="
grep -rniE "never commits|never auto-commit|git is the user|never branch|creates none" --include=*.md plugins/dev-workflows/commands/ready.md CLAUDE.md
echo "=== 7. /design worktree on-main test (expect the ref test instead) ==="
grep -nE "on main|cat-file -e" plugins/dev-workflows/commands/design.md
echo "=== 8. implement :718 scoping (expect 1) ==="
grep -c "handed off separately" plugins/dev-workflows/commands/implement.md
echo "=== 9. ard-resolution caller list (expect 5) ==="
grep -A1 "Cited by" plugins/dev-workflows/references/ard-resolution.md
echo "=== 10. next-phase-offer merge step (expect >=1) ==="
grep -ci "merged" plugins/dev-workflows/references/next-phase-offer.md
```

- [ ] **Step 2: Record every row with a verdict**

Write `docs/superpowers/plans/2026-08-14-residue-sweep.md` as a table: row, command run, expected, observed, verdict — **`fixed`** or **`checked and correct`**. Ten rows minimum, one per spec §7 row. Rows 5 and 6 need per-site sub-rows.

- [ ] **Step 3: Ask the residue question the greps cannot**

For each of the seven files this branch changed most, answer in writing: *"what did I make false?"* — not *"did my rule land everywhere?"* The second question finds nothing the greps missed; the first is what found `/ready`'s never-branches family during design.

Specifically re-read, and record a verdict for each:
- the frontmatter `description` of every command this branch touched (they are what the skills listing shows, and they duplicate claims from the body)
- `plugins/dev-workflows/README.md`'s reference list and command table (a parallel catalog of the `references/*.md` docs — every consumer list and count appears twice)
- `CLAUDE.md`'s invariant blocks

- [ ] **Step 4: Fix what the sweep found, then re-run Step 1**

Re-run and record the second pass. Both passes go in the sweep file.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/plans/2026-08-14-residue-sweep.md plugins/ CLAUDE.md
git commit -m "test(dev-workflows): canonical residue sweep — ten rows, verdicts for all

Closes the canonical half of Risk 3. Every row reports 'fixed' or
'checked and correct', never only the fixes — a sweep that lists only
fixes cannot be distinguished from a sample, and last round a review
named 3 stale lines where the exhaustive sweep found 6 of 34.

Step 3 asks 'what did I make false?' rather than 'did my rule land
everywhere?'. The first question is what found /ready's never-branches
family; the second would not have."
```

---

## Task 18: mgd port

**Files:**
- Modify: everything under `/workspace/mgd-claude-plugins/plugins/dev-workflows/` except the five identity files
- Modify: mgd's identity files by hand

**Interfaces:** Consumes Tasks 1–17.

- [ ] **Step 1: Create the branch and establish the real difference set**

```bash
cd /workspace/mgd-claude-plugins
git switch -c iv-gu/phase-handoff-gates
diff -rq /workspace/ihudak-claude-plugins/plugins/dev-workflows plugins/dev-workflows | sort
```

Record the output. Do **not** assume it is exactly the five identity files — verify. Last round the ship-pair difference set was 47 of 54 files at one point and 5 at another, and the distinction was time, not method.

- [ ] **Step 2: Port the content files**

For every file this branch changed in canonical **except** the five identity files, apply the same change to mgd. Prefer re-applying the edit to `patch`: last round `patch --fuzz=5` silently corrupted mgd's `CLAUDE.md` because its managed-docs section threw off context matching, and the corruption was caught only by a pre-commit read.

```bash
cd /workspace/ihudak-claude-plugins
git diff --name-only main...HEAD -- plugins/dev-workflows/ | grep -vE 'CHANGELOG|README|plugin.json|LICENSE|dependencies.md'
```

Those are the files to port. `references/phase-handoff.md` is a new file — copy it, then verify byte-identity.

- [ ] **Step 3: Hand-pass every identity file (Risk 5)**

The port skips these by design, they duplicate claims from elsewhere, and `diff -rq` reports them as expected-to-differ — three mechanisms that hide staleness. For **each** of `plugin.json`, `LICENSE`, `README.md`, `CHANGELOG.md`, `references/dependencies.md`, plus root `CLAUDE.md` and `.claude-plugin/marketplace.json`, answer in writing: *"does this file duplicate any claim Task 17's sweep changed?"* Record the answer **even when it is no**.

mgd's `README.md` is known to carry a parallel catalog of the reference docs — sweep its reference list and command table for the six-prefix authority, the PR statements, and the `/create-vi` grammar. mgd's `references/dependencies.md` naming `mgd-plugins` is **correct**, not drift.

- [ ] **Step 4: Version and CHANGELOG**

Bump mgd's `plugin.json` to `2.52.0` and write its own `## 2.52.0` entry, including the breaking change.

- [ ] **Step 5: Verify parity**

```bash
cd /workspace/mgd-claude-plugins
diff -rq /workspace/ihudak-claude-plugins/plugins/dev-workflows plugins/dev-workflows | sort
```

The differing set must be exactly the five identity files. Any other difference is either an unported change or an accidental edit — resolve it before committing. Then re-run Task 17's Step 1 sweep against mgd and record all ten verdicts.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(dev-workflows): 2.52.0 — phase-handoff gates (mgd port)

Content-verbatim with canonical except the five identity files, verified
by diff -rq rather than assumed.

Each identity file got a hand pass answering 'does this duplicate a claim
the sweep changed?', with the answer recorded even when no — the port
skips them, they duplicate claims from elsewhere, and diff -rq reports
them as expected-to-differ, so three mechanisms conspire to hide
staleness there. Four findings in sub-project I traced to exactly that.

Edits were re-applied rather than patched: last round patch --fuzz=5
silently corrupted mgd's CLAUDE.md."
```

---

## Task 19: copilot port

**Files:**
- Create: `/workspace/ihudak-copilot-plugins/dev-workflows/skills/_shared/phase-handoff.md`
- Modify: the copilot equivalents of every changed file, plus `.github/plugin/marketplace.json` and `.github/copilot-instructions.md`

**Interfaces:** Consumes Tasks 1–17.

- [ ] **Step 1: Create the branch and map the layout**

```bash
cd /workspace/ihudak-copilot-plugins
git switch -c iv-gu/phase-handoff-gates
ls dev-workflows/skills/ dev-workflows/skills/_shared/ | head -60
```

Commands live at `skills/<name>/SKILL.md`; references at `skills/_shared/<name>.md`.

- [ ] **Step 2: Hand-write `_shared/phase-handoff.md`**

**Never `cp`.** Write it in copilot dialect from Appendix A, applying all four rules:
1. `subagent_type:` → `agent_type:`
2. `${CLAUDE_PLUGIN_ROOT}/references/X.md` → `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/X.md`
3. any `§2.1 Sonnet chain` reference → copilot's own detection chain
4. command names in **colon form** — `idea:`, `create-vi:`, `ready:` — never `/idea`

- [ ] **Step 3: Port every other change in dialect**

Apply each canonical change by hand to the copilot equivalent. Then check dialect compliance across everything this branch touched:

```bash
cd /workspace/ihudak-copilot-plugins
git diff --name-only main...HEAD | while read -r f; do
  printf "%-64s subagent=%s claude_root=%s slash=%s\n" "$f" \
    "$(grep -c 'subagent_type:' "$f" 2>/dev/null)" \
    "$(grep -c 'CLAUDE_PLUGIN_ROOT' "$f" 2>/dev/null)" \
    "$(grep -coE '(^|[^a-z:])/(idea|create-vi|update-vi|create-ard|specify|design|implement|epics|ready)\b' "$f" 2>/dev/null)"
done
```

Every column must be `0`. A nonzero slash count is the dialect rule that bit twice before.

- [ ] **Step 4: The two depth-3 files**

Both went stale in a previous release and both must be updated:

```bash
grep -n "version" .github/plugin/marketplace.json
grep -niE "phase|handoff|prefix|create-vi" .github/copilot-instructions.md | head
```

Set the catalog to `2.22.0`. Add J's content to `copilot-instructions.md`: the new shared reference, the six-prefix authority, and the `/create-vi` → `create-vi:` grammar change.

- [ ] **Step 5: Version, CHANGELOG, and the README mirror**

Bump copilot's plugin version to `2.22.0`, write its `## 2.22.0` CHANGELOG entry including the breaking change, and sweep its `README.md` — last round it received 2 of 13 corrections while its CHANGELOG claimed the missing one had landed. Cross-check every CHANGELOG claim against `git diff --name-only main...HEAD`.

- [ ] **Step 6: Re-run the residue sweep against copilot**

Run Task 17 Step 1's ten checks, adapted to copilot paths, and record all ten verdicts.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat(dev-workflows): 2.22.0 — phase-handoff gates (copilot port)

Hand-written in copilot dialect; nothing cp'd. All four rules checked
mechanically across every file this branch touched — agent_type, the
_shared path form, the detection chain, and colon-form command names,
which is the rule that has bitten twice.

Both depth-3 files updated: .github/plugin/marketplace.json to 2.22.0 and
.github/copilot-instructions.md with the new shared reference, the
six-prefix authority and the create-vi: grammar change. Both went stale in
a previous release.

Every CHANGELOG claim cross-checked against git diff --name-only: last
round copilot's README got 2 of 13 corrections while its CHANGELOG
asserted the missing one had landed."
```

---

## Task 20: The verification record

**Files:**
- Create: `docs/superpowers/plans/2026-08-14-phase-handoff-gates-verification.md`

**Interfaces:** Consumes Tasks 1–19.

- [ ] **Step 1: Write it LAST, against the final tree**

Three of the 2026-08-07 round's records went stale because they were written before the last fix wave, and one was falsified by its own sub-project's next commit 17 minutes later. Write nothing here until Tasks 1–19 are complete and every fix has landed.

- [ ] **Step 2: One row per requirement**

53 rows, R1–R53: requirement, the exact command, expected value, observed value, PASS/FAIL. **Re-derive every expected value against the tree being verified** — never copy one from a task above. Two of the last round's wrong values propagated exactly that way.

- [ ] **Step 3: One row per risk mitigation**

Nine rows. For each, state what was actually run and what it showed:

| Risk | Mitigation | Where its evidence lives |
|---|---|---|
| 1 | reachability trace, one row per state | `2026-08-14-gate-reachability.md` |
| 2 | five receiving/acting line pairs | `2026-08-14-cross-cutting-checks.md` |
| 3 | ten sweep rows × three editions, verdicts for all | `2026-08-14-residue-sweep.md` + Tasks 18/19 |
| 4 | row B offers no switch — asserted by line range | Task 10 Step 6 |
| 5 | per-identity-file hand pass, answers recorded | Task 18 Step 3 |
| 6 | no producer reaches `handoff-to-main` except via the consent choice | Task 14 Step 1 |
| 7 | `gh pr create --dry-run` observed from another cwd | this plan's preamble; re-run and record |
| 8 | seven delegation rows with file:line proofs | Task 14 Step 4 |
| 9 | seven gate/first-expensive line pairs | Task 14 Step 2 |

- [ ] **Step 4: Re-check that each mitigation is SUFFICIENT, not merely present**

The user asked for this explicitly, twice. For each of the nine, answer: *"could this check pass while the risk still materialises?"* If yes, the mitigation is not sufficient — strengthen it and re-run. A check you cannot show would fail proves nothing, which is how 45/46 rows passed last round while 22 of 50 commands were unrunnable or vacuous.

Known-weak spots to examine first:
- Risk 7's `--dry-run` validates syntax and auth but **not** that the head branch exists — it accepted a nonexistent branch during planning. So it does not prove a real PR would open. Say so, and note what would: the first genuine handoff.
- Risk 1's trace is written by the same person who wrote the states. Have the reviewer re-derive at least three reaching conditions independently.
- Risk 3's sweep greps for patterns known in advance; it cannot find a claim family nobody thought of. That is what Task 17 Step 3's "what did I make false?" pass is for — confirm it was actually done and produced at least one finding, or explain why it produced none.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add docs/superpowers/plans/2026-08-14-phase-handoff-gates-verification.md
git commit -m "test(dev-workflows): J verification record — 53 requirements, 9 risk mitigations

Written last, against the final tree, with every expected value
re-derived rather than copied — three records last round went stale
because they were written before the final fix wave, and two wrong
expected values propagated by being copied between plans.

Each mitigation additionally answers 'could this pass while the risk
still materialises?'. Risk 7's --dry-run is recorded as insufficient on
its own: it validates syntax and auth but accepted a nonexistent head
branch during planning, so only the first genuine handoff proves a PR
opens."
```

---

## Self-review

**1. Spec coverage.** Every requirement named individually, so tracing is a grep and not an inference over range notation:

| Task | Requirements |
|---|---|
| T1 | R1, R2, R3, R4, R5, R6, R10 |
| T2 | R7, R8, R9, R53 |
| T3 | R29, R50, R51 |
| T4 | R31, R32, R33 |
| T5 | R34, R35, R41 |
| T6 | R11, R12, R37, and the `/idea` half of R36 |
| T7 | R13, R21, and the `/create-vi` half of R36 |
| T8 | R15, R16, R22, R23 |
| T9 | R14, R47 |
| T10 | R17, R24, R25 |
| T11 | R18, R26, R52 |
| T12 | R27 |
| T13 | R19, R28, R38, R49 |
| T14 | R20, R30 |
| T15 | R39, R40, R42 |
| T16 | R43 (canonical); T18 and T19 carry the mgd and copilot halves |
| T18 | R44 |
| T19 | R45, R46 |
| T20 | R48 — the invocation was executed during planning; T20 re-runs and records it |

Where R1–R10 land in Appendix A: R1 → §0–§1, R2 → §2.1–§2.5, R3 → §2.2's collision rule, R4 → §2.6's capability probe, R5 → §2.7, R6 → §2.8, R7 → §3.3, R8 → §3.6, R9 → §3.5, R10 → §4.1 and §4.4.

**2. Placeholder scan.** No "TBD", no "add error handling", no "similar to Task N". Every mechanical edit is a locate-command plus the replacement text. Every assertion is a runnable command with an expected value.

**3. Consistency.** The names Tasks 6–13 pass to `handoff-to-main` (`prefix`, `feature_folder`, `deliverable_paths`, `title`, `body_facts`) match Appendix A §2.9. The states Tasks 7–13 branch on (`pass`, `pass_amending`, `absent`, `unmanaged`, `stopped`, `branch`, `pr`, `degraded`) match Appendix A §3.7. The six prefixes are identical in T4, Appendix A §1 rule 3, and T15.

**One deliberate ordering choice:** Task 14's sweeps run after Tasks 6–13 rather than inside them, because a per-command check cannot see whether the consent wording drifted *between* commands — which is the failure it exists to catch.

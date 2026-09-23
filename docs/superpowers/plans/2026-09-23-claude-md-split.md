# CLAUDE.md Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Shrink the repo-root `CLAUDE.md` from 189,969 characters to under 40,000 by moving area-specific rules into path-scoped `.claude/rules/*.md` files and evidence into a never-auto-loaded `docs/maintainers/rationale.md`, losing no rule, and gate the result so it cannot regrow.

**Architecture:** There are three tiers:
- **Tier 1:** `CLAUDE.md`, always loaded. It holds every repo-wide rule, one line each, with a link to its evidence.
- **Tier 2:** five `.claude/rules/<area>.md` files. Each has a `paths:` frontmatter, so Claude Code loads it only after reading a matching file.
- **Tier 3:** `docs/maintainers/rationale.md`. It holds the evidence, one anchored section per rule.

Every block of the base `CLAUDE.md` gets exactly one row in a move table. Four gates change with the text: check 13 (vendor tokens) and checks 1–2 (links and anchors) widen to the new files, the ID-grammar gate stops skipping `docs/maintainers/`, and a new size check in `validate-catalog.py` fails `CLAUDE.md` above 40,000 characters.

**Tech Stack:** Markdown, bash (`scripts/check-docs.sh`, `scripts/check-id-grammar.sh`), Python 3 (`scripts/validate-catalog.py`), Claude Code CLI (`claude -p`) for the loading probe.

**Spec:** `docs/superpowers/specs/2026-09-22-claude-md-split-design.md` (approved 2026-09-23).

## Global Constraints

- **Base commit:** `d5f3034b`, the tip of `main` when this branch was cut. The spec's §5 inventory is re-taken on this base; the spec's own figures (186,894 chars, 186 blocks at `e22a6ee4`) are superseded by this plan's (189,969 chars, 185 non-heading blocks).
- **Size targets:**
  - `CLAUDE.md` should land at 28–32k characters. The hard cap is **40,000 characters**, and the gate warns above **36,000**.
  - Each `.claude/rules/*.md` warns above **20,000 characters**. Any rules file over 20,000 when its task ends is split by command group with narrower `paths:` globs (see Task 7). Do not leave it standing on the warning.
  - All sizes are Python `len(text)` of the UTF-8-decoded file, never bytes and never lines.
- **Every block moves; nothing is dropped silently** (spec §5.1). Every block of the base inventory gets exactly one move-table row: `block | lead words | destination | split? | notes`. A split row says which sentences went where.
- **A narrowing is a deletion** (spec §5.2). Compressing a rule to one line keeps every clause that constrains behaviour. A dropped clause is a `deletion` row with its ground, and "it looks derivable" is not a ground. A duplicate is a valid ground only when the row names the surviving copy and that copy was re-read.
- **Operative rule sentences move verbatim** (spec §5.3). Compression removes evidence, history and repetition around them, never the operative sentence itself.
- **Stale is not moved** (spec §5.4). A sentence found false while moving is fixed on the way and listed in the move table's notes.
- **One copy per rule** (spec §4). A rule that binds two areas goes to tier 1, never into two tier-2 files. Tier 1 and tier 2 never restate each other.
- **Evidence goes to tier 3, verbatim where it is still true.** A line number or count in it that has since moved is marked `*(as of d5f3034b)*`, never silently re-derived.
- **Why-links:** every tier-1 or tier-2 rule whose evidence moved ends with a why-link to its rationale section, written relative to the file it sits in:
  - in `CLAUDE.md`: `([why](docs/maintainers/rationale.md#<slug>))`
  - in `.claude/rules/*.md`: `([why](../../docs/maintainers/rationale.md#<slug>))`

  Rationale headings are `## <slug>`, where the slug is lower-case kebab and identical to the heading text, so GitHub's anchor equals the slug.
- **Pointers are re-read where they land.** Moved text changes what `this file`, `this document`, `this sentence`, `this paragraph`, `this bullet`, `this section`, `this list`, `here`, `above` and `below` point at. Every such word in moved text is rewritten to name its target explicitly unless its referent is unchanged, and the move-table notes record which. Example: *"Nothing gates any number written in this file"* becomes *"…written in `CLAUDE.md` or `.claude/rules/`"*.
- **Markers travel with their line.** `vendor-token-ok:` and `id-grammar-ok:` sanction only the line they sit on (or the fenced block they open). Every line of moved text that names a tracker keeps a marker, and a marker whose line no longer names one is dropped.
- **Plugins:** no file under `plugins/` changes unless Task 10 finds an inbound citation there. Any plugin file edited gets a patch version bump in its `plugin.json` and in `.claude-plugin/marketplace.json`, plus a dated `## [x.y.z] — 2026-09-23` CHANGELOG section. Never write `— Unreleased`; check 18 forbids it on main.
- **Gates:** run all nine as one `&&` chain from the worktree root and read the printed exit value (`CLAUDE.md` *Run the gates*):
  ```bash
  git add -A && python3 scripts/validate-catalog.py --selftest && python3 scripts/validate-catalog.py && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root . && ./scripts/check-docs.sh --selftest && ./scripts/check-docs.sh --root . && ASSERT_PUBLISHED=1 ./scripts/check-docs.sh --root . && npm ci --prefix scripts/mermaid --ignore-scripts --no-audit --no-fund && node scripts/mermaid/check-mermaid.mjs --selftest && node scripts/mermaid/check-mermaid.mjs --root . && python3 plugins/workflows-core/scripts/session-cost.py --selftest; echo "GATES_EXIT=$?"
  ```
  `git add -A` comes first because the mermaid gate reads tracked files only. It stages; it does not commit.
- **Git:**
  - Run `git branch --show-current` immediately before every commit; it must print `iv-gu/claude-md-split`.
  - Never use bare `git stash`, and never `git checkout`.
  - Commit messages go in a heredoc (`git commit -F - <<'EOF'`) and end with:
    ```
    Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
    Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU
    ```
- **Workspace:** `$WS` means this plan's SDD workspace. Set it at the start of every shell with `export WS="$(git rev-parse --show-toplevel)/.superpowers/sdd/2026-09-23-claude-md-split"`. The directory is git-ignored. The working artifacts live there: `base-CLAUDE.md`, `inventory.tsv`, `move-table.tsv`, `inbound.tsv`, `blocks.py`, `census.py`. Task 12 copies what the record needs into the committed verification record.
- **Other editions:** `check-docs.sh`'s body is byte-identical across three editions. The body changes Tasks 2 and 11 make are listed in the verification record under *Port to the other editions*. They are not ported here.

## Review Focus

1. **Moved text whose pointer now points somewhere else.** Example: *"this file"* inside a sentence moved from `CLAUDE.md` into `gates.md`. A reader would expect every pointer to still name what it named before. Task 3 installs a pointer grep, and every content task runs it on its destination files and adjudicates each hit in the move table.
2. **A rule that silently narrowed on compression.** A tier-1 one-liner can drop a clause such as *"…and a changelog is included in the sweep scope"*. A reader would expect the one-liner to bind exactly what the paragraph bound. The rule census (Task 12) finds every bold-led sentence of the base in tier 1 or tier 2, or lists it. Each content task's reviewer diffs its blocks' operative sentences against the destination.
3. **A rules file that never loads.** Causes include a wrong `paths:` syntax, a glob that misses the files people edit, or a file under a path Claude Code ignores. A reader would expect editing `brd-split.md` to bring the BRD rules into context. Task 1 proves the mechanism on a throwaway file before any text moves, and Task 12 re-proves it on the real files in both directions.
4. **A size gate that counts bytes.** Every `→` and `—` in `CLAUDE.md` is 3 bytes, so a byte count would fail a file that is in fact under 40,000 characters. A reader would expect "characters" to mean characters. Task 11 pins it with a 39,999-character fixture made of multi-byte characters, which must pass.
5. **Moved text escaping a gate it was under before.** `docs/` is excluded from the ID-grammar gate, the link checker never read `CLAUDE.md`, and check 13 reads only `CLAUDE.md` at root. A reader would expect every surface to stay gated after the move. Task 2 widens all three before any text moves, each with a red/green selftest pair.

---

### Task 1: Loading spike — prove `paths:` rules load on read, and only then

**Controller runs this task itself, not a subagent**: it launches a nested `claude -p`, and the no-subagents contract forbids implementers from doing that.

**Files:**
- Create (temporary, deleted in Step 5): `.claude/rules/zz-probe.md`

**Interfaces:**
- Produces: a recorded yes/no on whether a `.claude/rules/*.md` file carrying `paths:` frontmatter loads into a headless session run from the worktree after a matching `Read`, and not otherwise. The result goes in `$WS/progress.md`. Task 12's probe reuses the command shape verbatim.

- [ ] **Step 1: Write the probe rules file**

```bash
mkdir -p .claude/rules
cat > .claude/rules/zz-probe.md <<'EOF'
---
paths:
  - "plugins/product-workflows/commands/brd-split.md"
---

Probe sentence: the heron counts seven lanterns at the north gate.
EOF
```

- [ ] **Step 2: Positive run — read the matching file, then ask for the sentence**

```bash
claude -p --model claude-sonnet-5 --allowedTools Read --output-format stream-json --verbose \
  "Use the Read tool once, on plugins/product-workflows/commands/brd-split.md, limit 5 lines. Do not read any other file. Then answer: does any instruction loaded into your context mention a heron? If yes, quote that sentence verbatim. If no, answer exactly NOT LOADED." \
  > "$WS/probe-pos.jsonl"
grep -o '"file_path":"[^"]*"' "$WS/probe-pos.jsonl" | sort -u
tail -c 2000 "$WS/probe-pos.jsonl" | grep -o 'heron counts seven lanterns\|NOT LOADED' | head -1
```

Expected:
- the only `file_path` printed is `.../plugins/product-workflows/commands/brd-split.md`;
- the answer contains `heron counts seven lanterns`.

- [ ] **Step 3: Negative run — read a non-matching file**

```bash
claude -p --model claude-sonnet-5 --allowedTools Read --output-format stream-json --verbose \
  "Use the Read tool once, on README.md, limit 5 lines. Do not read any other file. Then answer: does any instruction loaded into your context mention a heron? If yes, quote that sentence verbatim. If no, answer exactly NOT LOADED." \
  > "$WS/probe-neg.jsonl"
grep -o '"file_path":"[^"]*"' "$WS/probe-neg.jsonl" | sort -u
tail -c 2000 "$WS/probe-neg.jsonl" | grep -o 'heron counts seven lanterns\|NOT LOADED' | head -1
```

Expected: only `README.md` was read, and the answer is `NOT LOADED`.

- [ ] **Step 4: Rule on the result**

If both runs match, append `Task 1: complete — paths: rules load on matching Read (pos quoted heron; neg NOT LOADED)` to `$WS/progress.md` and continue.

If the positive run fails, first retry once with the unquoted glob form `paths: ["plugins/product-workflows/**"]`. If it still fails, **stop and ask the user**: the whole design rests on this mechanism (spec §2), so it counts as a plan broken enough that every path forward is a guess.

- [ ] **Step 5: Remove the probe**

```bash
rm .claude/rules/zz-probe.md && rmdir .claude/rules 2>/dev/null; git status --short
```

Expected: a clean tree. Nothing is committed in this task.

---

### Task 2: Widen checks 1, 2 and 13, and the ID-grammar scan, to the new surfaces

**Files:**
- Modify: `scripts/check-docs.sh` — `check_links_and_anchors()` (the file list at its closing `done < <(...)`), `check_vendor_tokens()` (the `files=` lines), the check-13 header comment (the `SCOPE is $PLUGIN_REL plus CLAUDE.md` paragraph and the `Re-derive with` recipe), and `selftest()` (new cases after the existing check-13 CLAUDE.md pair).
- Modify: `scripts/check-id-grammar.sh` — `EXCLUDED_SUBTREES` and its comment, plus the `--selftest` block.

**Interfaces:**
- Produces: all three gates reading `CLAUDE.md`, `.claude/rules/*.md` and `docs/maintainers/*.md`. Later tasks rely on this, since every file they create is gated from its first commit.

- [ ] **Step 1: Write the failing selftest cases in `check-docs.sh`**

Insert directly after the existing `expect_pass_after "a MARKED vendor token in CLAUDE.md is accepted" ...` case:

```bash
  # Check 13 and checks 1-2 over the CLAUDE.md split's two new surfaces, each as a red/green
  # pair: an implementation that added the files but dropped the marker logic (13) or the
  # anchor resolution (2) passes every red case and fails its green twin.
  expect_fail "an unmarked vendor token in a .claude/rules file is rejected" 13 \
    "mkdir -p .claude/rules && printf -- '---\npaths:\n  - \"plugins/**\"\n---\n\nA stale claim about a Jira status.\n' > .claude/rules/area.md"
  expect_pass_after "a MARKED vendor token in a .claude/rules file is accepted" \
    "mkdir -p .claude/rules && printf -- '---\npaths:\n  - \"plugins/**\"\n---\n\nA stale claim about a Jira status. <!-- vendor-token-ok: fixture -->\n' > .claude/rules/area.md"
  expect_fail "an unmarked vendor token in docs/maintainers is rejected" 13 \
    "mkdir -p docs/maintainers && printf '# Rationale\n\nA stale claim about a Jira status.\n' > docs/maintainers/rationale.md"
  expect_pass_after "a MARKED vendor token in docs/maintainers is accepted" \
    "mkdir -p docs/maintainers && printf '# Rationale\n\nA stale claim about a Jira status. <!-- vendor-token-ok: fixture -->\n' > docs/maintainers/rationale.md"
  expect_fail "a broken link in CLAUDE.md is caught" 1 \
    "printf '\nSee [the rule](docs/maintainers/nowhere.md).\n' >> CLAUDE.md"
  expect_fail "a broken link in a .claude/rules file is caught" 1 \
    "mkdir -p .claude/rules && printf 'See [the rule](../../docs/maintainers/nowhere.md).\n' > .claude/rules/area.md"
  expect_fail "a why-link to a missing rationale anchor is caught" 2 \
    "mkdir -p docs/maintainers && printf '# Rationale\n\n## real-slug\n\nEvidence.\n' > docs/maintainers/rationale.md && printf '\nA rule. ([why](docs/maintainers/rationale.md#no-such-slug))\n' >> CLAUDE.md"
  expect_pass_after "a why-link to a present rationale anchor passes, from CLAUDE.md and from a rules file" \
    "mkdir -p docs/maintainers .claude/rules && printf '# Rationale\n\n## real-slug\n\nEvidence.\n' > docs/maintainers/rationale.md && printf '\nA rule. ([why](docs/maintainers/rationale.md#real-slug))\n' >> CLAUDE.md && printf 'A rule. ([why](../../docs/maintainers/rationale.md#real-slug))\n' > .claude/rules/area.md"
  expect_fail "a broken link inside docs/maintainers is caught" 1 \
    "mkdir -p docs/maintainers && printf '# Rationale\n\nSee [x](nowhere.md).\n' > docs/maintainers/rationale.md"
```

- [ ] **Step 2: Run the selftest and confirm the new cases fail**

Run: `./scripts/check-docs.sh --selftest 2>&1 | grep -E '^(FAIL|ok) .*(claude/rules|docs/maintainers|CLAUDE.md|why-link)'`

Expected:
- `FAIL` on the four red check-13/rules/maintainers cases and on the three check-1/2 red cases, because nothing reads those files yet;
- `ok` on the `expect_pass_after` cases, which pass vacuously today;
- the pre-existing two CLAUDE.md check-13 cases stay `ok`.

- [ ] **Step 3: Widen `check_vendor_tokens()`**

Replace the line

```bash
  [ -f "$root/CLAUDE.md" ] && files=$(printf '%s\n%s\n' "$files" "$root/CLAUDE.md")
```

with

```bash
  # The repo-root instruction tiers: CLAUDE.md, its path-scoped rules and the rationale they
  # link to. Text moved between them by the 2026-09-23 split stays under this check.
  local extra
  for extra in "$root/CLAUDE.md" "$root"/.claude/rules/*.md "$root"/docs/maintainers/*.md; do
    [ -f "$extra" ] && files=$(printf '%s\n%s\n' "$files" "$extra")
  done
```

- [ ] **Step 4: Widen `check_links_and_anchors()`**

Replace its closing file list

```bash
  done < <({ find "$root/$PLUGIN_REL/docs" -name '*.md' 2>/dev/null
             [ -f "$root/$PLUGIN_REL/README.md" ] && printf '%s\n' "$root/$PLUGIN_REL/README.md"
             [ -f "$root/README.md" ] && printf '%s\n' "$root/README.md"; })
```

with

```bash
  done < <({ find "$root/$PLUGIN_REL/docs" -name '*.md' 2>/dev/null
             [ -f "$root/$PLUGIN_REL/README.md" ] && printf '%s\n' "$root/$PLUGIN_REL/README.md"
             [ -f "$root/README.md" ] && printf '%s\n' "$root/README.md"
             # The instruction tiers: every why-link from CLAUDE.md or a rules file lands on
             # a docs/maintainers anchor, and a renamed rationale heading must turn this red.
             for extra in "$root/CLAUDE.md" "$root"/.claude/rules/*.md "$root"/docs/maintainers/*.md; do
               [ -f "$extra" ] && printf '%s\n' "$extra"
             done; })
```

- [ ] **Step 5: Update the check-13 header comment**

In the paragraph beginning `# SCOPE is $PLUGIN_REL plus CLAUDE.md.`, change that opening sentence to:

```
# SCOPE is $PLUGIN_REL plus the repo-root instruction tiers: CLAUDE.md, .claude/rules/*.md and docs/maintainers/*.md (the 2026-09-23 split moved CLAUDE.md's area rules and evidence into the latter two, and moved text must not escape the gate).
```

Keep the paragraph's hard-wrapped layout at the existing width. Change both copies of the recipe `grep -rn --exclude=CHANGELOG.md vendor-token-ok: plugins CLAUDE.md` in that comment to:

```
grep -rn --exclude=CHANGELOG.md vendor-token-ok: plugins CLAUDE.md .claude/rules docs/maintainers
```

Count the old recipe string wrap-insensitively before and after the edit. The after-count must be 0 in `scripts/check-docs.sh`.

- [ ] **Step 6: Run the selftest and the real run**

Run: `./scripts/check-docs.sh --selftest 2>&1 | tail -3; ./scripts/check-docs.sh --root .; echo EXIT=$?`

Expected: `SELFTEST PASS`, every new case `ok`, and `EXIT=0`. The real tree has no rules or maintainers files yet, and `CLAUDE.md` has no links.

- [ ] **Step 7: Write the failing ID-grammar selftest pair**

In `scripts/check-id-grammar.sh`, directly before the line `expect "a worktree copy at the scan root is not walked"  0 "$wtroot/green"`, add:

```bash
  # docs/: only docs/superpowers/ (design and verification records quoting the old form) is
  # history. docs/maintainers/ holds live rationale moved out of CLAUDE.md and is gated. A
  # PAIR: the green root proves docs/superpowers stays excluded, the red one proves
  # docs/maintainers is not -- a wholesale `docs` exclusion passes green and fails red.
  mkdir -p "$wtroot/green/docs/superpowers/verification" "$wtroot/maint/docs/maintainers"
  printf '# a record quoting the retired form\n\n[AC-1]\n' \
    > "$wtroot/green/docs/superpowers/verification/record.md"
  printf '# live rationale\n\n[FR-1]\n' > "$wtroot/maint/docs/maintainers/rationale.md"
```

and directly after the existing red `expect` call, add:

```bash
  expect "docs/maintainers is scanned although docs/superpowers is not" 1 "$wtroot/maint" "[FR-1]"
```

Run: `./scripts/check-id-grammar.sh --selftest`

Expected:
- the green case stays `ok`;
- the new case prints `FAIL  docs/maintainers is scanned although docs/superpowers is not: expected exit 1, got 0`;
- the run ends with `SELFTEST FAIL`.

- [ ] **Step 8: Narrow the exclusion**

Change

```bash
EXCLUDED_SUBTREES='^\./(docs|\.remember|\.superpowers|\.worktrees|worktrees|scripts/fixtures)/'
```

to

```bash
EXCLUDED_SUBTREES='^\./(docs/superpowers|\.remember|\.superpowers|\.worktrees|worktrees|scripts/fixtures)/'
```

In the comment list above it, change the line `#   docs/            -- this repo's design and verification records, which quote the old form` to:

```
#   docs/superpowers/ -- this repo's design and verification records, which quote the old form.
#                       docs/maintainers/ is NOT excluded: it is live rationale moved out of
#                       CLAUDE.md, and nothing about moving a rule exempts it from the grammar.
```

- [ ] **Step 9: Run both scans**

Run: `./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root .; echo EXIT=$?`

Expected: `SELFTEST PASS`, `PASS: no dash-form requirement IDs under .`, and `EXIT=0`.

- [ ] **Step 10: Full gate chain, then commit**

Run the Global Constraints gate chain. Expected: `GATES_EXIT=0`.

```bash
git branch --show-current   # must print iv-gu/claude-md-split
git commit -F - <<'EOF'
Gate the CLAUDE.md split's new surfaces before any text moves

Check 13 and checks 1-2 now read CLAUDE.md, .claude/rules/*.md and
docs/maintainers/*.md; the ID-grammar gate excludes only docs/superpowers/,
so live rationale moved out of CLAUDE.md stays under the grammar. Each new
surface has a red/green selftest pair.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU
EOF
```

---

### Task 3: Freeze the base, take the inventory, scaffold the tiers

**Files:**
- Create: `$WS/base-CLAUDE.md`, `$WS/blocks.py`, `$WS/inventory.tsv`, `$WS/move-table.tsv`, `$WS/inbound.tsv`, `$WS/pointers.sh` (all untracked)
- Create: `.claude/rules/gates.md`, `.claude/rules/product-workflows.md`, `.claude/rules/dev-workflows.md`, `.claude/rules/docs-workflows.md`, `.claude/rules/workflows-core.md`, `docs/maintainers/rationale.md`
- Modify: `CLAUDE.md` (insert the tier-1 skeleton headings only)

**Interfaces:**
- Produces:
  - Block ids `B001`…`B205`, in the numbering `blocks.py -v` prints on `base-CLAUDE.md`. Headings are numbered but not moved; 185 non-heading blocks get rows.
  - The move-table column order `block\tline\tkind\tchars\tsection\tlead\tdestination\tsplit\tnotes`, where `destination` is one of the six file paths, `deletion` or `CLAUDE.md`.
  - The tier-1 skeleton headings listed in Step 6.
  - The rationale file's heading convention.

- [ ] **Step 1: Freeze the base**

```bash
mkdir -p "$WS" && git show d5f3034b:CLAUDE.md > "$WS/base-CLAUDE.md" && python3 -c "import sys;print(len(open(sys.argv[1],encoding='utf-8').read()))" "$WS/base-CLAUDE.md"
```

Expected: `189969`.

- [ ] **Step 2: Write the inventory script**

`$WS/blocks.py`:

```python
"""Block inventory of a markdown file: paragraphs, list items, fenced blocks, headings.

python3 blocks.py FILE        -> per-section block counts and char totals
python3 blocks.py FILE -v     -> one TSV row per block (headings included, marked 'heading')
"""
import re
import sys
from collections import defaultdict

lines = open(sys.argv[1], encoding="utf-8").read().split("\n")
blocks, sec, cur, i = [], "(top)", None, 0


def flush():
    global cur
    if cur:
        blocks.append(cur)
        cur = None


while i < len(lines):
    line = lines[i]
    if line.startswith("```"):
        flush()
        j = i + 1
        while not lines[j].startswith("```"):
            j += 1
        blocks.append(dict(sec=sec, kind="fence", start=i + 1, text="\n".join(lines[i:j + 1])))
        i = j + 1
        continue
    if re.match(r"#{1,6} ", line):
        flush()
        if line.startswith("## "):
            sec = line[3:]
        blocks.append(dict(sec=sec, kind="heading", start=i + 1, text=line))
        i += 1
        continue
    if not line.strip():
        flush()
        i += 1
        continue
    if re.match(r"(- |\d+\. )", line):
        flush()
        cur = dict(sec=sec, kind="item", start=i + 1, text=line)
        i += 1
        continue
    if cur is None:
        cur = dict(sec=sec, kind="para", start=i + 1, text=line)
    else:
        cur["text"] += "\n" + line
    i += 1
flush()

if len(sys.argv) > 2:
    for n, b in enumerate(blocks, 1):
        lead = b["text"][:70].replace("\n", " ").replace("\t", " ")
        print(f"B{n:03d}\tL{b['start']}\t{b['kind']}\t{len(b['text'])}\t{b['sec'][:40]}\t{lead}")
else:
    agg = defaultdict(lambda: [0, 0])
    for b in blocks:
        if b["kind"] != "heading":
            agg[b["sec"]][0] += 1
            agg[b["sec"]][1] += len(b["text"])
    for s, (c, ch) in agg.items():
        print(f"{c:4d} {ch:7d}  {s}")
    print("non-heading blocks", sum(c for c, _ in agg.values()))
```

- [ ] **Step 3: Take the inventory and seed the move table**

```bash
python3 "$WS/blocks.py" "$WS/base-CLAUDE.md" | tail -1
python3 "$WS/blocks.py" "$WS/base-CLAUDE.md" -v > "$WS/inventory.tsv"
{ printf 'block\tline\tkind\tchars\tsection\tlead\tdestination\tsplit\tnotes\n'
  awk -F'\t' '$3!="heading"{print $0"\t\t\t"}' "$WS/inventory.tsv"; } > "$WS/move-table.tsv"
tail -n +2 "$WS/move-table.tsv" | wc -l
```

Expected: `non-heading blocks 185`, then `185`.

- [ ] **Step 4: Measure inbound citations**

```bash
grep -rn 'CLAUDE\.md' --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.worktrees \
  --exclude-dir=.superpowers --exclude=CHANGELOG.md . | grep -v '^\./CLAUDE\.md:' > "$WS/inbound-raw.txt"
wc -l < "$WS/inbound-raw.txt"
```

Classify every line into `$WS/inbound.tsv` (`file:line\tclass\tnote`), where `class` is one of:
- `this-repo`: it names, quotes or cites a section of this repository's root `CLAUDE.md`, e.g. `scripts/check-docs.sh`'s *"CLAUDE.md cites this comment"*;
- `target-repo`: it is about the `CLAUDE.md` of a repository a command or agent works on, e.g. `impl-maintenance`;
- `plugin-own`: it is about `plugins/obsidian-llm-wiki/CLAUDE.md`, a different file;
- `history`: it sits in a record under `docs/superpowers/` describing a past state, which spec §5.5 leaves as history.

Only `this-repo` rows are acted on (Task 10). The step is done when every raw line has a row: `wc -l` of both files agree.

- [ ] **Step 5: Write the pointer grep**

`$WS/pointers.sh`:

```bash
#!/usr/bin/env bash
# Every pointer word in the given files, for adjudication in move-table.tsv's notes column.
grep -nEo '.{0,40}\b([Tt]his (file|document|sentence|paragraph|bullet|section|list|refinement|rule)|[Hh]ere\b|above|below)\b.{0,40}' "$@"
```

`chmod +x "$WS/pointers.sh"`

- [ ] **Step 6: Scaffold the tier-1 skeleton in `CLAUDE.md`**

Insert these headings, each followed by one blank line, **immediately after** the `## Adding a new plugin` section's list and **before** `## Conventions`. Later tasks fill them; old sections below them are emptied block by block.

```markdown
## Where the rest of the guidance lives

## Editing discipline

## Hard constraints

## Running the gates

## Shared authorities
```

- [ ] **Step 7: Scaffold the rules files and the rationale file**

Each rules file gets exactly this frontmatter, then one line of purpose. `gates.md`:

```markdown
---
paths:
  - "scripts/**"
  - ".github/**"
---

# Gates — what each check enforces and cannot see

Loaded when a file under `scripts/` or `.github/` is read. Repo-wide rules are in `CLAUDE.md`; evidence is in `docs/maintainers/rationale.md`.
```

The other four follow the same shape:

| File | `paths:` entries | `#` heading |
|---|---|---|
| `product-workflows.md` | `"plugins/product-workflows/**"` | `# product-workflows — invariants, workflow map, agent callers` |
| `dev-workflows.md` | `"plugins/dev-workflows/**"` | `# dev-workflows — invariants, workflow map, agent callers` |
| `docs-workflows.md` | `"plugins/docs-workflows/**"`, `"plugins/product-workflows/commands/epics.md"`, `"plugins/product-workflows/agents/epic-*.md"`, `"plugins/product-workflows/docs/commands/epics.md"`, `"plugins/workflows-core/references/docs-grounding.md"` | `# docs-workflows — invariants, workflow map, agent callers` |
| `workflows-core.md` | `"plugins/workflows-core/**"` | `# workflows-core — shared git, handoff and routing invariants, agent callers` |

Ruling, recorded in the ledger: `docs-workflows.md` carries the `/epics` and `docs-grounding` globs. The base's *"Key invariants for `/document` (keyed mode) and `/epics`"* section states shared bullets for both commands, and the spec's table puts docs-grounding invariants in this file. Splitting shared bullets into two files would create two copies of one rule, which spec §4 forbids.

`docs/maintainers/rationale.md`:

```markdown
# Rationale — the evidence behind the repository's rules

Never auto-loaded. Each section holds the measured cases, refused widenings and history behind one rule in `CLAUDE.md` or `.claude/rules/`, which link here with `([why](…#<slug>))`. Read a section before proposing to change its rule. Figures marked *(as of d5f3034b)* were true on that commit and have not been re-derived.
```

- [ ] **Step 8: Gates and commit**

Run the gate chain. Expected: `GATES_EXIT=0`, since the new files hold no links and no tracker names.

Commit with the subject `Scaffold the CLAUDE.md tiers: rules files, rationale, tier-1 headings` and the standard trailer, after `git branch --show-current`.

---

### Content Tasks 4–9: common procedure

Every content task follows these steps for **its assigned blocks**:

1. For each block, decide which sentences are:
   - **operative**: they tell an agent what to do or not do, or define a term the rule uses;
   - **evidence**: measured cases, counts behind a decision, refused widenings, commit ids, "this file previously claimed", "bought by";
   - **repetition**: restates another block. Name that block.
2. Operative sentences go to the task's destination, verbatim, adjusted only as the Pointers constraint requires. Evidence goes to `docs/maintainers/rationale.md` under a `## <slug>` section named for the rule, verbatim. Repetition becomes a `deletion` row naming the surviving block.
3. Add the why-link to the operative text.
4. Delete the block from `CLAUDE.md`. When a section of the old layout is empty, delete its heading as well.
5. Fill the block's move-table row: `destination`, `split` (`no`, or `yes: <which sentences went where>`) and `notes` (pointer rewrites, stale fixes, deletion grounds).
6. Run `$WS/pointers.sh` on every file the task wrote to and adjudicate each hit in `notes`.
7. **Operative-text check.** For every non-`deletion` row of the task, run the check below: every operative sentence must be found wrap-insensitively in exactly one of `CLAUDE.md` or `.claude/rules/*.md`, and count 0 in the other tier. Paste the output into the task report.
   ```bash
   python3 - "$WS/base-CLAUDE.md" <<'EOF'
   import sys,re,glob
   norm=lambda s:re.sub(r'\s+',' ',s)
   tiers={'CLAUDE.md':norm(open('CLAUDE.md',encoding='utf-8').read())}
   for f in glob.glob('.claude/rules/*.md'): tiers[f]=norm(open(f,encoding='utf-8').read())
   for s in sys.stdin.read().split('\n'):
       s=norm(s).strip()
       if not s: continue
       where=[f for f,t in tiers.items() if s in t]
       print(f"{len(where)}\t{','.join(where) or 'MISSING'}\t{s[:80]}")
   EOF
   ```
   Feed it the operative sentences on stdin, one per line. A `0 MISSING` line is either a rewrite recorded in `notes` with the reason, or a defect.
8. Run the gate chain. `GATES_EXIT=0` is required.
9. Commit.

A task must not touch another task's blocks.

---

### Task 4: `gates.md` and the hard constraints

**Files:** Modify `CLAUDE.md`, `.claude/rules/gates.md` and `docs/maintainers/rationale.md`, and update `$WS/move-table.tsv`.

**Blocks and destinations** (base ids):

| Block | Lead | Operative text goes to | Evidence to rationale `## …` |
|---|---|---|---|
| B031 | description budget | `CLAUDE.md` § Hard constraints: the 1024/900 rule, whole-catalog rejection, *replace, never append*, release detail to CHANGELOG | `description-budget` |
| B032 | `[PREFIX#N]` IDs | `CLAUDE.md` § Hard constraints: the rule, the Jira auto-link reason in one clause (keep its `vendor-token-ok` marker), the gate and its `id-grammar-ok` marker. `gates.md`: selftest design (asserts every form named), marker census recipe, `spec-id-baseline.txt` | `id-grammar` (SM-C deletion, count history) |
| B036 | docs live in `plugins/<name>/docs/` | `CLAUDE.md` § Hard constraints: docs location, *README is a source of topics, never facts*, claims derived from the thing that runs it. `gates.md`: check-docs selftest shape and *no case count stated*. Page totals: to each plugin's own rules file (Tasks 5–8 pick them up from this row's notes) | `docs-tree` |
| B037 | run the gates as one chain | `CLAUDE.md` § Running the gates, whole | none (no evidence in it) |
| B038 | nothing gates any number; checks 1–19 | `CLAUDE.md` § Editing discipline: *nothing gates a number in `CLAUDE.md` or `.claude/rules/`; re-derive; prefer a citation; count the thing, not your rendering, and state the command beside the number*. `gates.md`: one subsection per check (`### Check N`) holding what it gates, what it deliberately excludes or cannot see, and each refused widening **as a rule** (*"Check 11 is not widened past `/brd-*` and `/prd-*`; see why"*). The check-13 scope sentence is rewritten to the widened scope from Task 2, and marker counts are re-derived with the Task 2 recipe | `number-gating`, `check-9` … `check-19` as needed, `stop-routing-no-check` |
| B039 | mermaid | `CLAUDE.md` § Hard constraints: *quote any node or edge label containing `[ ] ( ) { } \|` or `#`*, with the example. `gates.md` `### Mermaid gate`: lexer-not-regex, tracked files only, fixture exclusion, failure location by content, *what it cannot see*, the local run command | `mermaid-gate` |
| B040 | `choices:` arity | `CLAUDE.md` § Hard constraints: 2–4 options, no authored Other, free text in customer-authority pickers is normalised or re-asked and never written through, a fifth option moves to prose (next-phase-offer overflow, epic-picker *The cap*) | `choices-arity` |

- [ ] **Step 1:** Apply the common procedure to B031, B032, B036, B037, B038, B039 and B040.
- [ ] **Step 2:** `gates.md` must be ≤ 20,000 characters (`python3 -c "print(len(open('.claude/rules/gates.md',encoding='utf-8').read()))"`). If it is over, move further evidence out; the gates are code, and their rules fit.
- [ ] **Step 3:** Gate chain, then commit `CLAUDE.md split: gates rules and hard constraints`.

---

### Task 5: `dev-workflows.md`

**Blocks and destinations:**

| Block(s) | Operative to | Notes |
|---|---|---|
| B008 | `CLAUDE.md` § Active plugins keeps a ≤ 400-character paragraph: what it ships, what it depends on, that it does not use `prose-style`. The extraction history (three extractions, none coming back) goes to `dev-workflows.md` | — |
| B068 (bug-diagnosis), B072 (code-handoff) | `dev-workflows.md` `## Authorities`, whole paragraphs. Their one-line index entries in `CLAUDE.md` § Shared authorities are written by Task 9; write `index: Task 9` in each row's notes | the `§2.8`→heading citation history in B072 → rationale `code-handoff-citation` |
| B082 map lines for `/implement`, `/vuln`, `/upgrade`, `/design`, `/ready`; the agent-tree lines for agents under `plugins/dev-workflows/agents/` | `dev-workflows.md` `## Workflow map`, in one fenced block keeping the base's alignment | the map is `split: yes`; its row lists every line id this task took, by command name |
| *Key invariants enforced by all three code-oriented commands* (all bullets), *Key invariants for `/implement`* (all bullets) | `dev-workflows.md` `## Invariants`, same sub-headings | the `code-handoff` citation-shift history → rationale |
| *PRD-creation flow* bullets about `/design` (interface-designer fan-out) and `/ready` (read-only about status) | `dev-workflows.md` `## Invariants` → `### /design and /ready` | the other PRD-creation bullets are Task 6's, and two are Task 9's (see there) |
| *Test-writing requirement* (B176–B182) | `dev-workflows.md` `## Test-writing requirement`, operative text verbatim | the Mocha 12.0.2 measurement and the *rejected alternative* paragraph → rationale `test-writing-requirement` |
| B036's page-total note for dev-workflows | `dev-workflows.md` `## Docs tree`: `20 pages` with its breakdown | — |

Use `grep -n` on `$WS/base-CLAUDE.md` for each bullet's exact text. The move-table ids for Key-invariants bullets are the `B` ids `inventory.tsv` gives them.

- [ ] **Step 1:** Apply the common procedure to every block above.
- [ ] **Step 2:** `dev-workflows.md` must be ≤ 20,000 characters. Over that, split `## Test-writing requirement` into `.claude/rules/dev-workflows-tests.md` with `paths:` `"plugins/dev-workflows/commands/implement.md"`, `"plugins/dev-workflows/agents/test-*.md"`, `"plugins/dev-workflows/docs/commands/implement.md"`, and record the ruling in the ledger.
- [ ] **Step 3:** Gate chain, then commit `CLAUDE.md split: dev-workflows rules`.

---

### Task 6: `product-workflows.md`

| Block(s) | Operative to | Notes |
|---|---|---|
| B009 | `CLAUDE.md` § Active plugins: ≤ 600 characters covering the ladder, `/epics`, the six-command route, the two proposal commands, dependencies (`workflows-core`, `prose-style`, no absent case), and three env vars. `product-workflows.md` `## Plugin facts` gets the rest: `brd-` names the route, not the folder kind; `/prd-ground` alone leaves the route; four route commands refuse a root; proposals gate nothing downstream, with the full reader list verbatim | — |
| B082 map lines for `/idea`, `/create-prd`, `/update-prd`, `/create-ard`, `/specify`, `/epics`, `/brd-intake`, `/brd-split`, `/prd-ground`, `/brd-interview`, `/brd-package`, the customer-review line, `/brd-reconcile`, `/prd-proposal`, `/brd-proposal`, `BRD route (tail)`; the agent-tree lines for agents under `plugins/product-workflows/agents/` | `product-workflows.md` `## Workflow map`. The `/epics` line and `epic-writer`/`epic-reviewer` lines go here too; the `docs-workflows.md` globs load this file's neighbour, not this line | the `BRD route (tail)` line's design-spec §7.2 history (`git show 62e791e8:…`) stays operative (*"do not write 'routed to its seed'"*) |
| *PRD-creation flow* bullets except the `/design`, `/ready` (Task 5), ARD-respect and *a phase is not finished* (Task 9) bullets | `product-workflows.md` `## Invariants` | — |
| B036's page-total note for product-workflows | `product-workflows.md` `## Docs tree` | — |

- [ ] **Step 1:** Apply the common procedure.
- [ ] **Step 2:** If `product-workflows.md` is over 20,000 characters, split the BRD route into `.claude/rules/brd-route.md` with `paths:` `"plugins/product-workflows/commands/brd-*.md"`, `"plugins/product-workflows/commands/prd-ground.md"`, `"plugins/product-workflows/references/*"`, `"plugins/product-workflows/agents/*"`, `"plugins/product-workflows/docs/brd-workflow.md"`. It takes the slice-kind, PRD-eligibility, sibling re-cut and route-detection invariants and the route's map lines. Record the ruling.
- [ ] **Step 3:** Gate chain, then commit `CLAUDE.md split: product-workflows rules`.

---

### Task 7: `docs-workflows.md`

| Block(s) | Operative to | Notes |
|---|---|---|
| B010 | `CLAUDE.md` § Active plugins: ≤ 600 characters covering the seven commands in one clause, dependencies, the three `prose-style-checker` roles in one clause, and *`/docs-serve` is a pure utility*. `docs-workflows.md` `## Plugin facts` gets the agent list, the reference counts and the role detail | the *"This sentence used to call the dispatch a fallback"* history → rationale `prose-style-roles` |
| B065, B066, B074, B075, B076 | `docs-workflows.md` `## Authorities`, whole | B066's re-litigation guard (*"recorded here so it is not re-litigated"*) stays operative; the reasons go with it |
| B082 map lines for `/document (direct)`, `/docs-profile`, `/docs-init`, `/docs-brand`, `/docs-serve`, `/docs-audit`, `/document (keyed)`, `/release-notes`; the agent-tree lines for agents under `plugins/docs-workflows/agents/` | `docs-workflows.md` `## Workflow map` | — |
| Key invariants for `/document` (direct), `/document` (keyed) and `/epics`, `/release-notes`, and `$DOCS_PATH` docs grounding | `docs-workflows.md` `## Invariants`, same sub-headings | — |
| B036's page-total note for docs-workflows | `docs-workflows.md` `## Docs tree` | — |

- [ ] **Step 1:** Apply the common procedure.
- [ ] **Step 2:** If `docs-workflows.md` is over 20,000 characters (expected: the `/docs-serve` map line alone is ~5,000), move the `/docs-serve` map line and any `/docs-serve`-only text into `.claude/rules/docs-serve.md` with `paths:` `"plugins/docs-workflows/commands/docs-serve.md"`, `"plugins/docs-workflows/docs/commands/docs-serve.md"`, `"plugins/docs-workflows/references/render-verification.md"`, `"plugins/docs-workflows/references/toolchain-preflight.md"`. Leave one line in `docs-workflows.md` naming that file. If still over, move `### /release-notes` into `.claude/rules/release-notes.md` with `paths:` `"plugins/docs-workflows/commands/release-notes.md"`, `"plugins/docs-workflows/agents/release-notes-writer.md"`, `"plugins/docs-workflows/references/release-note-types.md"`, `"plugins/docs-workflows/docs/commands/release-notes.md"`. Record each ruling.
- [ ] **Step 3:** Gate chain, then commit `CLAUDE.md split: docs-workflows rules`.

---

### Task 8: `workflows-core.md`

| Block(s) | Operative to | Notes |
|---|---|---|
| B011 | `CLAUDE.md` § Active plugins: ≤ 500 characters covering what core carries, the two session-wide hooks, and *all three family plugins declare it; no degraded mode* | detail to `workflows-core.md` `## Plugin facts` |
| B062 | `workflows-core.md` `## Model routing callers`: the 26-command list, the exempt utility commands with reasons, and the agent-receives-block rule with its grep | — |
| B064, B067, B069, B070, B071, B073, B077, B078, B079 | `workflows-core.md` `## Authorities`, whole paragraphs | B069's *"Match the execution phrase, not the bare name"* and the thirty-vs-twenty-nine recipe → rationale `recipe-returns-wrong-answer`; its rule line goes to `CLAUDE.md` § Editing discipline in Task 9 |
| B081 | Deletion, **except** its last sentence (agents marked `(plugin)` ship from that plugin and are dispatched as `subagent_type: "<plugin>:<agent>"`) → `workflows-core.md` `## Workflow map` preamble | ground: the command-to-plugin assignments restate `CLAUDE.md` § Active plugins' four paragraphs, re-read after Tasks 5–8 |
| B082 map line for `/frames (core)`; the *All twenty-nine in-scope commands…* paragraph inside the fence; agent-tree lines for agents under `plugins/workflows-core/agents/` | `workflows-core.md` `## Workflow map` | — |
| Key invariants for specs-repo git (all bullets) | `workflows-core.md` `## Invariants` → `### Specs-repo git` | — |
| B036's page-total note for workflows-core | `workflows-core.md` `## Docs tree` | — |

- [ ] **Step 1:** Apply the common procedure.
- [ ] **Step 2:** After this task, `B082` must be fully accounted for. Every line of the base fence appears in exactly one of the four rules files' `## Workflow map` blocks:
  ```bash
  python3 - "$WS/base-CLAUDE.md" <<'EOF'
  import sys,glob
  base=open(sys.argv[1],encoding='utf-8').read()
  fence=base.split('## Workflow relationships',1)[1].split('```',2)[1].split('\n')[1:]
  rules={f:open(f,encoding='utf-8').read() for f in glob.glob('.claude/rules/*.md')}
  for l in fence:
      if not l.strip(): continue
      hits=[f for f,t in rules.items() if l.strip() in t]
      if len(hits)!=1: print(len(hits), l[:90])
  print('checked',sum(1 for l in fence if l.strip()))
  EOF
  ```
  Expected: only the `checked N` line.
- [ ] **Step 3:** Size ≤ 20,000, or split the `## Authorities` section into `.claude/rules/workflows-core-git.md` (specs-repo-git, phase-handoff, read-only-repos) with `paths:` `"plugins/workflows-core/references/specs-repo-git.md"`, `"plugins/workflows-core/references/phase-handoff.md"`, `"plugins/workflows-core/references/read-only-repos.md"`, `"plugins/dev-workflows/references/code-handoff.md"`. Record the ruling.
- [ ] **Step 4:** Gate chain, then commit `CLAUDE.md split: workflows-core rules`.

---

### Task 9: Tier 1 — editing discipline, shared-authority index, the rest of `CLAUDE.md`

**Blocks and destinations:**

| Block | Operative to `CLAUDE.md` § | Evidence |
|---|---|---|
| B033 | Hard constraints: keys are folder names, validated for shape only against `workflows-core:addressing` §1; `pre-lint`'s collision grep is an autolink detector and is never widened; `workitem_key` is preserved and never minted (keep the `vendor-token-ok` marker) | `one-key-namespace` |
| B034 | Editing discipline: resolve an identifier against a known set, never parse one out of free text; with no set, report the absence; `specs-repo-git` §3.5 `branch-key` is the worked example | `resolve-against-a-known-set` |
| B035 | Editing discipline: the root rule (*a note saying a feature does not ship is a claim with an expiry date; when a capability lands, sweep by phrase for the sentences that said it would not, and rewrite each against what ships*), then **eight numbered one-line refinements**, each keeping its operative clauses: (1) a hit dispositions the whole paragraph; (2) back the phrase sweep with an end-to-end read of every touched phase; (3) run an exclusivity probe as its own axis, the five phrases then the noun forms (keep the full noun list verbatim), generalising from a claim's wording, with the record `docs/superpowers/verification/2026-09-23-exclusivity-probe-wider-vocabulary.md` named; (4) scope is `plugins/` including every `CHANGELOG.md`, plus root `README.md`, plus `CLAUDE.md`, `.claude/rules/` and `docs/maintainers/`; reading the cited phase proves containment, not uniqueness, and pick the mode first in a two-mode command; (5) a correction fires the sweep too; (6) sweep the claim's subject, never any one site's wording; (7) count the exact string before and after, wrap-insensitively (collapse whitespace in file and pattern, match, map back), and bound an addition's count by context the new text cannot contain; (8) a change to a claim's extent falsifies its whole population, `docs/` pages included, and write one noun across copies without searching by it | `claim-expiry-sweep`, with subsections `### refinement-1` … `### refinement-8` holding every measured case verbatim |
| B041 | Editing discipline: the extent face (enumerate the cases the new extent reaches and read each against its neighbours; qualify by the class, not the member; re-read the whole paragraph after adding an effect or reason) and the pointer face (re-read a sentence from where it lands for pointers and omitted subjects; the `this <file-kind>` tell) — plus *a third check makes it a `workflows-core` reference* | `sentence-context` |
| B042 | Editing discipline, whole rule sentence | `verification-record-last` |
| B043 | Editing discipline: measure the population a fix serves first, as a count, per finding; where it is none, fix the claim; newly shipped machinery is the counter-case | `measure-the-population` |
| B044 | Editing discipline: before inlining a shared rule, itemise what the shared file still says line by line; *a rewrite that narrows is a deletion* | `drift-risk` |
| (from Task 8's B069 row) | Editing discipline: *re-measure in one place and cite it everywhere else; a recipe that returns a wrong answer is worse than none — match the execution phrase, not the bare name* | `recipe-returns-wrong-answer` (already written by Task 8) |
| PRD-creation *ARD respect* bullet; *a phase is not finished until its artifact is on the specs repo's default branch* bullet | Hard constraints (both span plugins) | — |
| B012–B018 | Keep in § Active plugins / *Internal reference convention*. B016's *"verified in a live run… 33 literal tokens"* and *"This file previously claimed the opposite"* → rationale | `plugin-root-expansion` |
| B026–B030 | A `## Conventions` list directly after `## Adding a new plugin`, whole (they are already one line each) | — |
| B055–B061 | § Model routing, whole | — |
| B064–B079 | § Shared authorities: one line per reference, `` `<path>` — <what it owns, ≤ 160 chars>; detail in `.claude/rules/<file>.md` `` (the full paragraphs were moved by Tasks 5, 7 and 8) | — |
| B184–B195 | § Updating installed plugins: the four `update` commands, restart needed, no `reinstall`, update `prose-style` with docs-workflows past 1.1.3, update the plugin that holds the file, `marketplace update` does not update installed plugins, `/plugins` does, a rename blocks every plugin's update, `validate` and `tag` | `plugin-update-cli` (the *previously claimed* histories and the 1.0.0/1.1.0 measurement) |
| B197–B199 | Keep whole | — |
| B201–B204 | § Git, operative text whole, plus a new bullet: **Never bare `git stash`** — the stash stack is shared with every worktree and session; use a WIP commit, or `git stash push -u -m <tag>` and `apply <sha>` | B203's cross-session incident → rationale `verify-branch-before-commit` |
| — | § Where the rest of the guidance lives: a table of the rules files that exist after Tasks 4–8 (file, its `paths:` in one cell, what it holds), one sentence on the trigger (*a rules file loads when you read a matching file; a Bash `grep` or `git diff` does not load it, so read a file in the area before editing there*), and a pointer to `docs/maintainers/rationale.md` (*never auto-loaded; read a rule's section before proposing to change the rule*) | — |
| — | Remove every old section heading left empty by Tasks 4–8: `## Conventions` (the old one; the new short list replaces it), `## Source-truth reference`, `## Workflow relationships…`, `## Key invariants`, `## Test-writing requirement…` | — |

- [ ] **Step 1:** Apply the common procedure to every block above.
- [ ] **Step 2:** Every row of `$WS/move-table.tsv` now has a non-empty `destination`:
  ```bash
  awk -F'\t' 'NR>1 && $7==""{print $1}' "$WS/move-table.tsv"
  ```
  Expected: no output.
- [ ] **Step 3:** Size check: `python3 -c "print(len(open('CLAUDE.md',encoding='utf-8').read()))"` is at most 40,000, aiming for 28,000–32,000. Over 36,000, move more evidence out before continuing; Task 11's gate will warn above it.
- [ ] **Step 4:** Gate chain, then commit `CLAUDE.md split: tier 1 — editing discipline, authority index, the rest`.

---

### Task 10: Re-point inbound citations

**Files:** every `this-repo` row of `$WS/inbound.tsv`.

- [ ] **Step 1:** For each `this-repo` row, rewrite the citation so it names where the text now lives: `CLAUDE.md` § …, `.claude/rules/<file>.md`, or `docs/maintainers/rationale.md#<slug>`. Take the location from the move table.
  - Known rows to expect: `scripts/check-docs.sh` near its check-11 comment (*"CLAUDE.md has always said the family comes from the scope paragraph"*) and its check-16 comment (*"CLAUDE.md cites this comment"*).
  - A citation of a rule that stayed in `CLAUDE.md` needs no edit; record it `unchanged`.
- [ ] **Step 2:** If any edited file is under `plugins/<name>/`, apply the Global Constraints plugin-release rule for that plugin.
- [ ] **Step 3:** For each rewritten citation string, count the old string before and after the edit, wrap-insensitively. The after-count must be 0.
- [ ] **Step 4:** Gate chain, then commit `CLAUDE.md split: re-point inbound citations`.

---

### Task 11: The size gate in `validate-catalog.py`

**Files:** Modify `scripts/validate-catalog.py` (constants, new function, the call in `validate_repo`, `_selftest`, the module docstring).

**Interfaces:**
- Produces: `check_instruction_sizes(root: Path) -> tuple[int, int]` returning `(errors, warnings)`, called at the end of `validate_repo()` before its `OK` line.

- [ ] **Step 1: Write the failing selftest cases**

Add these keyword arguments to `build()`:

```python
              claude_md: str | None = None, rules: dict[str, str] | None = None,
```

At the end of `build()`'s body, add:

```python
        if claude_md is not None:
            (root / "CLAUDE.md").write_text(claude_md, encoding="utf-8")
        for rel, text in (rules or {}).items():
            path = root / ".claude" / "rules" / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")
```

Before `print("SELFTEST PASS" ...)`, add:

```python
    # The instruction-file budget. Characters, not bytes: every `→` and `—` is three bytes,
    # so a byte count would fail a file that is under the budget -- the multi-byte case
    # below passes only if the gate counts characters.
    case("CLAUDE.md at the limit passes", True, "OK", claude_md="x" * CLAUDE_MD_MAX)
    case("CLAUDE.md one character over the limit is rejected", False,
         f"CLAUDE.md is {CLAUDE_MD_MAX + 1} characters", claude_md="x" * (CLAUDE_MD_MAX + 1))
    case("CLAUDE.md of multi-byte characters under the limit passes", True, "OK",
         claude_md="→" * (CLAUDE_MD_MAX - 1))
    case("CLAUDE.md past the warning threshold is reported", True, "WARN  CLAUDE.md",
         claude_md="x" * (CLAUDE_MD_WARN + 1))
    case("a rules file past its threshold is reported", True, "WARN  .claude/rules/area.md",
         rules={"area.md": "x" * (RULES_FILE_WARN + 1)})
    case("a repository with no CLAUDE.md passes", True, "OK")
```

Run: `python3 scripts/validate-catalog.py --selftest`

Expected: `NameError: name 'CLAUDE_MD_MAX' is not defined`.

- [ ] **Step 2: Implement**

After `DESCRIPTION_WARN = 900`, add:

```python
# The repo-root CLAUDE.md loads into every session and every non-fork subagent here. It
# reached 189,969 characters by accretion before the 2026-09-23 split moved area rules to
# .claude/rules/ (loaded by path) and evidence to docs/maintainers/rationale.md (never
# loaded). Characters, not bytes or lines: the budget is context, and the file is unwrapped
# paragraphs, so a line count means nothing.
CLAUDE_MD_MAX = 40_000
CLAUDE_MD_WARN = 36_000
RULES_FILE_WARN = 20_000
```

After `check_description`, add:

```python
def check_instruction_sizes(root: Path) -> tuple[int, int]:
    """Return (errors, warnings) for the repo-root instruction tiers' size budget."""
    errors = warnings = 0
    claude = root / "CLAUDE.md"
    if claude.is_file():
        size = len(claude.read_text(encoding="utf-8"))
        if size > CLAUDE_MD_MAX:
            print(
                f"  ERROR CLAUDE.md is {size} characters, limit is {CLAUDE_MD_MAX} -- "
                f"move a rule that binds one area to .claude/rules/<area>.md, and "
                f"evidence to docs/maintainers/rationale.md"
            )
            errors += 1
        elif size > CLAUDE_MD_WARN:
            print(
                f"  WARN  CLAUDE.md is {size} characters, nearing the {CLAUDE_MD_MAX} "
                f"limit -- move evidence to docs/maintainers/rationale.md now"
            )
            warnings += 1
    for rules_file in sorted((root / ".claude" / "rules").glob("*.md")):
        size = len(rules_file.read_text(encoding="utf-8"))
        if size > RULES_FILE_WARN:
            rel = rules_file.relative_to(root)
            print(
                f"  WARN  {rel} is {size} characters, past {RULES_FILE_WARN} -- split it "
                f"by command group with narrower paths: globs, or move evidence to "
                f"docs/maintainers/rationale.md"
            )
            warnings += 1
    return errors, warnings
```

In `validate_repo`, immediately before `if errors == 0 and warnings == 0:`, add:

```python
    e, w = check_instruction_sizes(root)
    errors += e
    warnings += w
```

Add one paragraph to the module docstring, after the paragraph describing the description budget:

```
It also enforces the repo-root instruction budget: ``CLAUDE.md`` fails above 40,000
characters and warns above 36,000, and each ``.claude/rules/*.md`` warns above 20,000.
```

- [ ] **Step 3: Run the selftest and the real run**

Run: `python3 scripts/validate-catalog.py --selftest && python3 scripts/validate-catalog.py; echo EXIT=$?`

Expected: every case `ok`, `SELFTEST PASS`, `0 error(s), 0 warning(s)` and `EXIT=0`. Any `WARN` on the real run is a rules file the content tasks left over 20,000, which Global Constraints says to split; fix it before committing.

- [ ] **Step 4:** In `CLAUDE.md` § Running the gates, add one sentence stating the number once: *"`scripts/validate-catalog.py` fails `CLAUDE.md` above 40,000 characters and warns above 36,000; a rules file warns above 20,000 — overflow belongs in a rules file or the rationale."* Then run the gate chain and commit `Gate the instruction files' size: CLAUDE.md 40k, rules files 20k`.

---

### Task 12: Census, loading probe, verification record

**Controller runs Step 3 itself** (a nested `claude -p`).

**Files:**
- Create: `docs/superpowers/verification/2026-09-23-claude-md-split.md`
- Modify: `CLAUDE.md` or rules files only where a check below finds a defect

- [ ] **Step 1: Rule census** (spec §8)

`$WS/census.py`:

```python
"""Every bold span of the base CLAUDE.md, located in the new tiers (whitespace-collapsed)."""
import glob
import re
import sys

norm = lambda s: re.sub(r"\s+", " ", s)
base = open(sys.argv[1], encoding="utf-8").read()
spans = [norm(m).strip() for m in re.findall(r"\*\*(.+?)\*\*", base, flags=re.S)]
tiers = {"CLAUDE.md": norm(open("CLAUDE.md", encoding="utf-8").read())}
for f in sorted(glob.glob(".claude/rules/*.md")):
    tiers[f] = norm(open(f, encoding="utf-8").read())
rationale = norm(open("docs/maintainers/rationale.md", encoding="utf-8").read())
seen = set()
for s in spans:
    if s in seen or len(s) < 12:
        continue
    seen.add(s)
    t12 = [f for f, t in tiers.items() if s in t]
    where = ",".join(t12) if t12 else ("rationale" if s in rationale else "MISSING")
    flag = "DUP" if len(t12) > 1 else ""
    print(f"{where}\t{flag}\t{s[:100]}")
```

Run: `python3 "$WS/census.py" "$WS/base-CLAUDE.md" > "$WS/census.tsv"; cut -f1,2 "$WS/census.tsv" | sort | uniq -c`

Expected: no `DUP`. Every `MISSING` and every `rationale` line is adjudicated in the record:
- `rationale`: evidence whose operative content is stated in tier 1/2 in other words. Name where.
- `MISSING`: a deletion row in the move table, or a defect to fix now.

- [ ] **Step 2: Final accounting**

```bash
tail -n +2 "$WS/move-table.tsv" | wc -l            # 185
awk -F'\t' 'NR>1 && $7==""' "$WS/move-table.tsv" | wc -l   # 0
python3 -c "print(len(open('CLAUDE.md',encoding='utf-8').read()))"
for f in .claude/rules/*.md docs/maintainers/rationale.md; do python3 -c "import sys;print(len(open(sys.argv[1],encoding='utf-8').read()),sys.argv[1])" "$f"; done
grep -rn --exclude=CHANGELOG.md 'vendor-token-ok:' plugins CLAUDE.md .claude/rules docs/maintainers | wc -l
```

Re-derive the vendor-marker census, lines and files, and update the figure in `scripts/check-docs.sh`'s check-13 header and in `gates.md`'s check-13 subsection to match. Count the old figure string wrap-insensitively afterwards; it must be 0 in both files.

- [ ] **Step 3: Loading probe on the real files** (controller)

Positive: the sibling re-cut rule loads after reading `brd-split.md`. Take its first sentence from `.claude/rules/` with `grep -h 'The sibling re-cut is the one place' .claude/rules/*.md`, then confirm it is absent from `CLAUDE.md`:

```bash
grep -c 'sibling re-cut is the one place' CLAUDE.md   # expected 0
claude -p --model claude-sonnet-5 --allowedTools Read --output-format stream-json --verbose \
  "Use the Read tool once, on plugins/product-workflows/commands/brd-split.md, limit 5 lines. Read no other file. Then quote verbatim, from the instructions loaded into your context, the sentence that begins 'The sibling re-cut is the one place'. If it is not in your context, answer exactly NOT LOADED." \
  > "$WS/probe-real-pos.jsonl"
grep -o '"file_path":"[^"]*"' "$WS/probe-real-pos.jsonl" | sort -u
grep -o "sibling re-cut is the one place[^\"]\{0,80\}\|NOT LOADED" "$WS/probe-real-pos.jsonl" | tail -1
```

Expected: only `brd-split.md` read, and the quote returned.

Negative: the same prompt with `README.md` instead. Expected: only `README.md` read, and `NOT LOADED`.

Record both outputs' last lines in the record.

- [ ] **Step 4: Write the verification record** (written last, per `CLAUDE.md` § Editing discipline)

`docs/superpowers/verification/2026-09-23-claude-md-split.md` holds:
- Sizes before (189,969) and after, per file, from Step 2.
- The move table: `move-table.tsv` rendered as a markdown table. Escape `|` in cells.
- The census summary and each `rationale`/`MISSING` adjudication.
- The loading-probe results.
- Every ruling from the ledger: the `/epics` globs, and any split done under a 20k rule.
- The Task 1 spike result.
- The inbound-citation table.
- `## Port to the other editions`: the `check-docs.sh`, `check-id-grammar.sh` and `validate-catalog.py` changes by function name. They are not ported here.

- [ ] **Step 5:** Run the gate chain; `GATES_EXIT=0` is required. Commit `CLAUDE.md split: verification record`.

---

## Self-review notes

- **Spec coverage:**

  | Spec section | Covered by |
  |---|---|
  | §3.1 target | Tasks 9 and 11 |
  | §3.2 mechanism | Tasks 1 and 3 |
  | §3.3 three tiers | Tasks 3–9 |
  | §3.4 regrowth gate | Task 11 |
  | §4 contents per tier | Tasks 4–9 tables |
  | §5.1–5.4 moving rules | Global Constraints and the common procedure |
  | §5.5 inbound citations | Tasks 3 and 10 |
  | §6 check 13 | Task 2 |
  | §6 id-grammar | Task 2 (a gap: the spec assumed it already scanned `docs/`) |
  | §6 checks 14 and mermaid | unchanged, still covering |
  | §7 size gate | Task 11 |
  | §8 verification | Task 12 |
  | §10 anchor rot | Task 2 widens the link checker |

- **Deviations from the spec, each a ruling:**
  - `docs-workflows.md` carries `/epics` and `docs-grounding` globs.
  - A tier-2 file over 20k is split rather than left warning.
  - A new `## Conventions` short list is kept in tier 1.
  - The Git section gains the never-bare-stash rule the spec's tier-1 list names.

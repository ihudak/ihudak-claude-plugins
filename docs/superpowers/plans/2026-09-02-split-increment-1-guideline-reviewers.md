# Marketplace split, increment 1 — extract `guideline-reviewers`

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the two guideline-review commands, their two agents, and their 38 reference files out of `dev-workflows` into a new `guideline-reviewers` plugin, proving the multi-plugin machinery on the one part of the tree that shares nothing.

**Architecture:** `scripts/check-docs.sh` is taught to check a *list* of plugins before a second plugin exists, and the fixture gains a second plugin so that loop is provably non-vacuous. Only then is the new plugin created, registered, and filled. Nothing in this increment uses the loader skill, declares a dependency, or rewrites a citation — those arrive in increment 2.

**Tech Stack:** Bash (the gate), Python 3 (catalog validation), Markdown, JSON.

**Spec:** `docs/superpowers/specs/2026-09-02-marketplace-split-design.md`

## Global Constraints

- **No behaviour changes.** Every command does exactly what it did at `pre-split`. (Spec §9)
- **`scripts/check-docs.sh`'s body is byte-identical across three editions** — `ihudak-claude-plugins`, `mgd-claude-plugins`, `ihudak-copilot-plugins` — so a fix ports by plain `cp` of the body. **Only the edition-config block (lines 17–48) may differ per repo.** Any multi-plugin support must therefore live in the config block as data, with the body reading it generically.
- **Three gates must pass before every commit:** `./scripts/check-docs.sh --root .`, `./scripts/check-id-grammar.sh --root .`, `python3 scripts/validate-catalog.py`.
- **`check-docs.sh --selftest` must pass**, and any new check behaviour needs a case paired with the broken implementation it catches. A gate that cannot be shown to fail proves nothing when it passes.
- **Plugin descriptions are capped at 1024 characters** in both `plugin.json` and the `marketplace.json` entry; `validate-catalog.py` fails above it and warns above 900.
- **Rollback point:** tag `pre-split` at `527a9c7`.
- **File moves use `git mv`**, so history follows the file.

## File Structure

| Path | Responsibility |
|---|---|
| `scripts/check-docs.sh` (modify, config block + dispatch tail) | Iterate a plugin list instead of one constant |
| `scripts/fixtures/docs/pass/plugins/fixture-two/**` (create) | A second fixture plugin, so the loop is exercised |
| `plugins/guideline-reviewers/.claude-plugin/plugin.json` (create) | New plugin manifest |
| `plugins/guideline-reviewers/{README.md,LICENSE}` (create) | Plugin front page and licence |
| `plugins/guideline-reviewers/docs/**` (create) | Its own documentation tree — index, getting-started, 2 command pages, 2 reference pages |
| `plugins/guideline-reviewers/{commands,agents,references}/**` (moved) | The 42 files |
| `.claude-plugin/marketplace.json` (modify) | Register the plugin |
| `README.md` (modify) | Add its install line — required by check 7 |
| `plugins/dev-workflows/docs/**`, `README.md`, `CHANGELOG.md`, `CLAUDE.md` (modify) | Reconcile counts after the removal |

---

### Task 1: Teach the gate to check a list of plugins

**Files:**
- Modify: `scripts/check-docs.sh:20` (config block) and `scripts/check-docs.sh:1311-1332` (dispatch tail)

**Interfaces:**
- Produces: the shell variable `PLUGIN_RELS` (space-separated plugin paths, config block) and a dispatch loop that sets `PLUGIN_REL` per iteration. Every existing check function keeps reading the global `PLUGIN_REL` and is **not** edited.

- [ ] **Step 1: Confirm the gate passes now, so any later failure is attributable**

```bash
./scripts/check-docs.sh --root . && ./scripts/check-docs.sh --selftest | tail -1
```
Expected: `PASS: docs are consistent with the plugin under plugins/dev-workflows` and `SELFTEST PASS`.

- [ ] **Step 2: Replace the scalar in the config block**

In `scripts/check-docs.sh`, replace line 20:

```bash
PLUGIN_REL="plugins/dev-workflows"   # copilot: dev-workflows
```

with:

```bash
# Space-separated; the dispatch loop sets PLUGIN_REL from it per iteration, so every
# check function below is unchanged and still reads a single PLUGIN_REL. A one-element
# list behaves exactly as the old scalar did, which is what keeps this body portable to
# editions that ship one plugin.
PLUGIN_RELS="${PLUGIN_RELS:-plugins/dev-workflows}"   # copilot: dev-workflows
```

The `:-` form is deliberate: the selftest re-invokes this script against a fixture tree whose plugin set differs from the real one, and an environment override is how it points the fixture run at both without a second copy of the config.

- [ ] **Step 3: Replace the dispatch tail with a loop**

Replace everything from `[ -d "$ROOT/$PLUGIN_REL/docs" ] || { fail 4 ...` to the end of the file with:

```bash
[ "$HAVE_PY" = 1 ] || note "python3 not found; falling back to ASCII slugs -- anchors whose heading contains a non-ASCII letter cannot be verified here"

for PLUGIN_REL in $PLUGIN_RELS; do
  if [ ! -d "$ROOT/$PLUGIN_REL/docs" ]; then
    fail 4 "$PLUGIN_REL/docs does not exist"
    continue
  fi
  check_links_and_anchors   "$ROOT"
  check_orphans             "$ROOT"
  check_inventory           "$ROOT"
  check_env_vars            "$ROOT"
  check_table_cells         "$ROOT"
  check_install_block       "$ROOT"
  check_cost_attribution    "$ROOT"
  check_prose_counts        "$ROOT"
  check_identity_quarantine "$ROOT"
  check_merge_clause        "$ROOT"
  check_choices_arity       "$ROOT"
  check_vendor_tokens       "$ROOT"
  check_foreign_identity    "$ROOT"
  check_index_membership    "$ROOT"
done

if [ "$FAILURES" -gt 0 ]; then
  echo "FAIL: $FAILURES problem(s) under $PLUGIN_RELS" >&2
  exit 1
fi
echo "PASS: docs are consistent with the plugin(s) under $PLUGIN_RELS"
```

- [ ] **Step 4: Verify behaviour is unchanged with a one-element list**

```bash
./scripts/check-docs.sh --root . ; echo "exit=$?"
./scripts/check-docs.sh --selftest | tail -1
```
Expected: `PASS: docs are consistent with the plugin(s) under plugins/dev-workflows`, `exit=0`, and `SELFTEST PASS`. All 14 checks still run — a one-element loop is the old behaviour.

- [ ] **Step 5: Verify a missing docs dir still fails, and no longer aborts the run**

```bash
tmp=$(mktemp -d); cp -R scripts/fixtures/docs/pass/. "$tmp/"
mv "$tmp/plugins/dev-workflows/docs" "$tmp/plugins/dev-workflows/docs-moved"
./scripts/check-docs.sh --root "$tmp" 2>&1 | grep -c 'FAIL check 4'; rm -rf "$tmp"
```
Expected: at least `1` — the missing-docs case still reports check 4.

- [ ] **Step 6: Commit**

```bash
git add scripts/check-docs.sh
git commit -m "refactor(gate): check-docs iterates a plugin list

PLUGIN_REL becomes PLUGIN_RELS, a space-separated list in the edition-config
block, and the dispatch tail loops over it setting PLUGIN_REL per iteration. No
check function changes -- each still reads a single PLUGIN_REL -- so the body
stays byte-identical across editions, which the config block requires.

A one-element list is exactly the old behaviour, so this ships green with one
plugin and is what lets a second plugin be checked at all. A missing docs dir
now reports and continues to the next plugin instead of aborting the run."
```

---

### Task 2: Prove the loop is real by giving the fixture a second plugin

**Files:**
- Create: `scripts/fixtures/docs/pass/plugins/fixture-two/.claude-plugin/plugin.json`
- Create: `scripts/fixtures/docs/pass/plugins/fixture-two/commands/omega.md`
- Create: `scripts/fixtures/docs/pass/plugins/fixture-two/docs/README.md`
- Create: `scripts/fixtures/docs/pass/plugins/fixture-two/docs/getting-started.md`
- Create: `scripts/fixtures/docs/pass/plugins/fixture-two/docs/commands/omega.md`
- Modify: `scripts/fixtures/docs/pass/README.md` (add the install line check 7 pins against)
- Modify: `scripts/check-docs.sh` selftest (fixture `PLUGIN_RELS` override + two cases)

**Interfaces:**
- Consumes: `PLUGIN_RELS` from Task 1.
- Produces: fixture plugin `fixture-two` with exactly one command `omega`, no agents, no references, no hooks — the minimum a plugin needs to pass all 14 checks.

- [ ] **Step 1: Write the failing case first — a second plugin the gate does not yet look at**

Add to `selftest()` in `scripts/check-docs.sh`, immediately before the closing `printf 'SELFTEST PASS\n'`:

```bash
  expect_fail "second plugin's command page is checked too" 4 \
    'rm plugins/fixture-two/docs/commands/omega.md'
  expect_fail "second plugin's docs index is checked too" 2 \
    'printf "\n[dangling](nowhere.md)\n" >> plugins/fixture-two/docs/README.md'
```

- [ ] **Step 2: Run the selftest to verify both cases fail**

```bash
./scripts/check-docs.sh --selftest 2>&1 | grep -E 'second plugin'
```
Expected: two `FAIL` lines — the fixture has no `fixture-two`, so the mutations touch nothing and the gate stays green when the case expects red.

- [ ] **Step 3: Create the second fixture plugin**

```bash
cd scripts/fixtures/docs/pass
mkdir -p plugins/fixture-two/.claude-plugin plugins/fixture-two/commands plugins/fixture-two/docs/commands

cat > plugins/fixture-two/.claude-plugin/plugin.json <<'EOF'
{
  "name": "fixture-two",
  "version": "1.0.0",
  "description": "Second fixture plugin. Exists so the gate's plugin loop is exercised by more than one element.",
  "author": { "name": "Fixture" }
}
EOF

cat > plugins/fixture-two/commands/omega.md <<'EOF'
---
name: omega
description: Fixture command in the second plugin.
---

Fixture body.
EOF

cat > plugins/fixture-two/docs/README.md <<'EOF'
# fixture-two documentation

| I want to… | Go to |
|---|---|
| install this | [Getting started](getting-started.md) |
| run omega | [`/omega`](commands/omega.md) |

## Commands

- [`/omega`](commands/omega.md) — fixture command.
EOF

cat > plugins/fixture-two/docs/getting-started.md <<'EOF'
# Getting started

```bash
claude plugin marketplace add fixture/fixture-marketplace
claude plugin install fixture-two@fixture-marketplace
claude plugin marketplace update fixture-marketplace
```
EOF

cat > plugins/fixture-two/docs/commands/omega.md <<'EOF'
# `/omega`

Fixture command page. Reached from the [index](../README.md).
EOF
cd ../../../..
```

- [ ] **Step 4: Add the second plugin's install line to the fixture root README**

Check 7 requires every install line in a plugin's `getting-started.md` to also appear in the repo-root README. Append to `scripts/fixtures/docs/pass/README.md`:

```bash
printf '\nclaude plugin install fixture-two@fixture-marketplace\n' >> scripts/fixtures/docs/pass/README.md
```

- [ ] **Step 5: Point the selftest's fixture run at both plugins**

The fixture tree is checked by re-invoking this same script, which reads `PLUGIN_RELS` from its own config block — so the fixture needs the list to include both. Add to `selftest()`, immediately after `fixture="$here/fixtures/docs/pass"`:

```bash
  # The fixture tree ships two plugins so the dispatch loop is exercised by more than
  # one element. A one-element run cannot distinguish "the loop works" from "the loop
  # runs once and the body ignores it".
  export PLUGIN_RELS="plugins/dev-workflows plugins/fixture-two"
```

The config block already reads `${PLUGIN_RELS:-…}` from Task 1, so no further edit is needed there.

- [ ] **Step 6: Run the selftest — both new cases must now pass**

```bash
./scripts/check-docs.sh --selftest 2>&1 | tail -4
```
Expected: `ok    second plugin's command page is checked too (check 4 fired)`, `ok    second plugin's docs index is checked too (check 2 fired)`, and `SELFTEST PASS`.

- [ ] **Step 7: Verify the real tree is unaffected**

```bash
./scripts/check-docs.sh --root . ; echo "exit=$?"
```
Expected: `PASS` and `exit=0` — the real run has no `PLUGIN_RELS` in the environment, so it falls back to the single real plugin.

- [ ] **Step 8: Commit**

```bash
git add scripts/check-docs.sh scripts/fixtures/docs/pass
git commit -m "test(gate): fixture gains a second plugin so the loop is not vacuous

Task 1's loop runs once against one plugin, which cannot distinguish a working
loop from a body that ignores it. The fixture now ships fixture-two -- one
command, its page, an index and a getting-started -- and two selftest cases
mutate it: a deleted command page must fire check 4, a dangling index link must
fire check 2. Both fail before the fixture exists and pass after, which is the
pairing this gate's own header demands.

PLUGIN_RELS is overridable from the environment so the selftest can point the
fixture run at both plugins while the real run keeps its single default."
```

---

### Task 3: Create and register the empty `guideline-reviewers` plugin

**Files:**
- Create: `plugins/guideline-reviewers/.claude-plugin/plugin.json`
- Create: `plugins/guideline-reviewers/LICENSE` (copy of `plugins/dev-workflows/LICENSE`)
- Create: `plugins/guideline-reviewers/README.md`
- Create: `plugins/guideline-reviewers/docs/README.md`
- Create: `plugins/guideline-reviewers/docs/getting-started.md`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `README.md` (repo root)
- Modify: `scripts/check-docs.sh:20` (add the plugin to `PLUGIN_RELS`)

**Interfaces:**
- Consumes: `PLUGIN_RELS` from Tasks 1–2.
- Produces: plugin name `guideline-reviewers`, version `1.0.0`, marketplace entry `"source": "./plugins/guideline-reviewers"`.

- [ ] **Step 1: Create the plugin manifest and licence**

```bash
mkdir -p plugins/guideline-reviewers/.claude-plugin plugins/guideline-reviewers/docs
cp plugins/dev-workflows/LICENSE plugins/guideline-reviewers/LICENSE

cat > plugins/guideline-reviewers/.claude-plugin/plugin.json <<'EOF'
{
  "name": "guideline-reviewers",
  "version": "1.0.0",
  "description": "Reviews an OpenAPI specification against bundled REST API and IAM permission-naming guidance, and reviews application code or UI against bundled public design-system and accessibility standards. Ships the guidance it reviews against — Google AIP, Zalando, Microsoft REST, OpenAPI 3.1 and ~20 RFCs for APIs; Apple HIG, Material Design 3, Microsoft Fluent 2, W3C WCAG 2.2, ARIA APG and NN/g for interfaces — plus a Spectral ruleset that runs against a spec directly. Standalone: it consumes no workflow artefact and produces none.",
  "author": { "name": "Ivan Gudak", "email": "ihudak@gmail.com" },
  "homepage": "https://github.com/ihudak/ihudak-claude-plugins",
  "repository": "https://github.com/ihudak/ihudak-claude-plugins",
  "license": "MIT",
  "keywords": ["openapi", "rest", "accessibility", "design-system", "review"]
}
EOF
python3 -c "import json;d=json.load(open('plugins/guideline-reviewers/.claude-plugin/plugin.json'));print('description chars:',len(d['description']))"
```
Expected: a number below 900.

- [ ] **Step 2: Write the plugin README and docs index**

```bash
cat > plugins/guideline-reviewers/README.md <<'EOF'
# guideline-reviewers

Two standalone review commands, and the guidance they review against.

| Command | Reviews | Against |
|---------|---------|---------|
| [`/api-guideline-reviewer`](docs/commands/api-guideline-reviewer.md) | An OpenAPI specification | Bundled REST API and IAM permission-naming guidance, plus a Spectral ruleset |
| [`/guideline-reviewer`](docs/commands/guideline-reviewer.md) | Application code or UI | Bundled public design-system and accessibility standards |

Neither command consumes a workflow artefact or produces one. See [the documentation index](docs/README.md).
EOF

cat > plugins/guideline-reviewers/docs/README.md <<'EOF'
# guideline-reviewers documentation

| I want to… | Go to |
|---|---|
| install this and set it up | [Getting started](getting-started.md) |
| review an OpenAPI specification | [`/api-guideline-reviewer`](commands/api-guideline-reviewer.md) |
| review code or a UI against design and accessibility standards | [`/guideline-reviewer`](commands/guideline-reviewer.md) |
| see which agents ship here | [Agents](reference/agents.md) |
| see what guidance is bundled | [References](reference/references.md) |

## Commands

- [`/api-guideline-reviewer`](commands/api-guideline-reviewer.md) — review an OpenAPI specification against the bundled REST API and IAM permission-naming guidance.
- [`/guideline-reviewer`](commands/guideline-reviewer.md) — review application code or a UI against the bundled design-system and accessibility standards.

## Reference

- [Agents](reference/agents.md) — the two subagents these commands dispatch.
- [References](reference/references.md) — the bundled guidance corpora.
EOF
```

- [ ] **Step 3: Write getting-started with the install lines check 7 pins**

```bash
cat > plugins/guideline-reviewers/docs/getting-started.md <<'EOF'
# Getting started

Add the marketplace, then install this plugin:

```bash
claude plugin marketplace add ihudak/ihudak-claude-plugins
claude plugin install guideline-reviewers@ihudak-plugins
```

To pick up later changes:

```bash
claude plugin marketplace update ihudak-plugins
```

Nothing else is required — neither command reads an environment variable, and neither depends on another plugin.
EOF
```

- [ ] **Step 4: Add the install line to the repo-root README**

Check 7 requires each plugin's `getting-started.md` install lines to be a subset of the repo-root README's. Insert after the `acli` line (`README.md:36`):

```bash
python3 - <<'PY'
p="README.md"; s=open(p,encoding="utf-8").read()
old="claude plugin install acli@ihudak-plugins"
assert old in s and "guideline-reviewers@" not in s
s=s.replace(old, old+"\nclaude plugin install guideline-reviewers@ihudak-plugins",1)
open(p,"w",encoding="utf-8").write(s)
PY
grep -n 'guideline-reviewers@' README.md
```
Expected: one line.

- [ ] **Step 5: Register the plugin in the catalog**

```bash
python3 - <<'PY'
import json
p=".claude-plugin/marketplace.json"; d=json.load(open(p))
pl=json.load(open("plugins/guideline-reviewers/.claude-plugin/plugin.json"))
assert not any(x["name"]=="guideline-reviewers" for x in d["plugins"])
d["plugins"].append({
  "name": "guideline-reviewers", "version": pl["version"],
  "description": pl["description"], "author": pl["author"],
  "category": "productivity", "source": "./plugins/guideline-reviewers",
  "homepage": pl["homepage"],
})
open(p,"w",encoding="utf-8").write(json.dumps(d,indent=2,ensure_ascii=False)+"\n")
PY
python3 scripts/validate-catalog.py
```
Expected: `0 error(s), 0 warning(s)`.

- [ ] **Step 6: Add the plugin to the gate's list**

In `scripts/check-docs.sh`, change the `PLUGIN_RELS` default to:

```bash
PLUGIN_RELS="${PLUGIN_RELS:-plugins/dev-workflows plugins/guideline-reviewers}"   # copilot: dev-workflows
```

- [ ] **Step 7: Run all three gates**

```bash
./scripts/check-docs.sh --root . ; echo "docs=$?"
./scripts/check-id-grammar.sh --root . >/dev/null; echo "id=$?"
python3 scripts/validate-catalog.py >/dev/null; echo "catalog=$?"
./scripts/check-docs.sh --selftest | tail -1
```
Expected: `docs=0`, `id=0`, `catalog=0`, `SELFTEST PASS`. The new plugin has no commands, agents, references or hooks yet, so every inventory check passes over an empty set.

- [ ] **Step 8: Commit**

```bash
git add plugins/guideline-reviewers .claude-plugin/marketplace.json README.md scripts/check-docs.sh
git commit -m "feat(guideline-reviewers): create and register the empty plugin

The manifest, licence, README, documentation index and getting-started page,
registered in the catalogue and added to the gate's plugin list -- with no
content moved yet. An empty plugin passes every inventory check over an empty
set, so this step is independently green and isolates 'can the repo carry a
second plugin' from 'did the move go right'.

The install line lands in the repo-root README in the same commit because check
7 pins each plugin's getting-started block against it."
```

---

### Task 4: Move the 42 files and their documentation

**Files:**
- Move: `plugins/dev-workflows/commands/{api-guideline-reviewer,guideline-reviewer}.md` → `plugins/guideline-reviewers/commands/`
- Move: `plugins/dev-workflows/agents/{api-guideline-reviewer,guideline-reviewer}.md` → `plugins/guideline-reviewers/agents/`
- Move: `plugins/dev-workflows/references/{api-guidelines,guidelines}` → `plugins/guideline-reviewers/references/`
- Move: `plugins/dev-workflows/docs/commands/{api-guideline-reviewer,guideline-reviewer}.md` → `plugins/guideline-reviewers/docs/commands/`
- Create: `plugins/guideline-reviewers/docs/reference/agents.md`
- Create: `plugins/guideline-reviewers/docs/reference/references.md`

**Interfaces:**
- Consumes: the registered plugin from Task 3.
- Produces: `plugins/guideline-reviewers` containing 2 commands, 2 agents, 38 reference files (26 under `api-guidelines/`, 12 under `guidelines/`).

- [ ] **Step 1: Confirm nothing outside the two commands reads the corpora**

```bash
grep -rl 'references/guidelines\|references/api-guidelines' \
  plugins/dev-workflows/commands plugins/dev-workflows/agents plugins/dev-workflows/references \
  | grep -v 'guideline-reviewer' | grep -v 'references/api-guidelines/'
```
Expected: no output. If any file is listed, **stop** — the spec's zero-coupling premise is wrong and the increment order needs revisiting.

- [ ] **Step 2: Move the files with git mv**

```bash
mkdir -p plugins/guideline-reviewers/{commands,agents,references,docs/commands,docs/reference}
for n in api-guideline-reviewer guideline-reviewer; do
  git mv "plugins/dev-workflows/commands/$n.md"      "plugins/guideline-reviewers/commands/$n.md"
  git mv "plugins/dev-workflows/agents/$n.md"        "plugins/guideline-reviewers/agents/$n.md"
  git mv "plugins/dev-workflows/docs/commands/$n.md" "plugins/guideline-reviewers/docs/commands/$n.md"
done
git mv plugins/dev-workflows/references/api-guidelines plugins/guideline-reviewers/references/api-guidelines
git mv plugins/dev-workflows/references/guidelines     plugins/guideline-reviewers/references/guidelines
echo "moved: cmds=$(ls plugins/guideline-reviewers/commands|wc -l) agents=$(ls plugins/guideline-reviewers/agents|wc -l) refs=$(find plugins/guideline-reviewers/references -type f|wc -l)"
```
Expected: `moved: cmds=2 agents=2 refs=38`.

- [ ] **Step 3: Write the agent inventory page**

check 4 requires a row per agent matching `^| \`<name>\``.

```bash
cat > plugins/guideline-reviewers/docs/reference/agents.md <<'EOF'
# Agents

Both agents are dispatched by the command of the same name. Neither is a user entry point.

| Agent | Dispatched by | What it does |
|-------|---------------|--------------|
| `api-guideline-reviewer` | [`/api-guideline-reviewer`](../commands/api-guideline-reviewer.md) | Reads an OpenAPI specification and reports where it departs from the bundled REST API and IAM permission-naming guidance. |
| `guideline-reviewer` | [`/guideline-reviewer`](../commands/guideline-reviewer.md) | Reads application code or a UI description and reports where it departs from the bundled design-system and accessibility standards. |
EOF
```

- [ ] **Step 4: Write the reference inventory page**

check 4 requires each subtree to be claimed as `` `dir/` (N) `` with N matching the tree.

```bash
cat > plugins/guideline-reviewers/docs/reference/references.md <<'EOF'
# References

This plugin bundles the guidance it reviews against, so a review cites a file that ships with it rather than a page on the internet that may have moved.

| Subtree | Files | What it holds |
|---------|-------|---------------|
| `api-guidelines/` (26) | REST API guidance, IAM permission-naming guidance, an OpenAPI template, and a Spectral ruleset | Derived from Google AIP, Zalando, Microsoft REST guidelines, OpenAPI 3.1 and the RFCs they cite |
| `guidelines/` (12) | Design-system and accessibility guidance, plus a checklist template and a checker script | Derived from Apple HIG, Material Design 3, Microsoft Fluent 2, W3C WCAG 2.2, ARIA APG and NN/g |

`api-guidelines/spectral/ruleset.yaml` runs against a specification directly; `guidelines/check_guidelines.py` is invoked by the review flow. Everything else is prose the agents read.
EOF
```

- [ ] **Step 5: Run the gates**

```bash
./scripts/check-docs.sh --root . ; echo "docs=$?"
python3 scripts/validate-catalog.py >/dev/null; echo "catalog=$?"
```
Expected: `docs=1` — `dev-workflows`'s own docs still claim the two commands and their references. That is Task 5's work, and seeing it fail here confirms the both-directions inventory check is doing its job. Record the failure list; do **not** fix it in this task.

- [ ] **Step 6: Verify the new plugin alone is internally consistent**

```bash
PLUGIN_RELS="plugins/guideline-reviewers" ./scripts/check-docs.sh --root . ; echo "exit=$?"
```
Expected: `PASS` and `exit=0` — the moved plugin is self-consistent even while `dev-workflows` is not.

- [ ] **Step 7: Verify every bundled path the moved files cite still resolves**

The gates check inventories, not whether a command can find what it reads. Each `${CLAUDE_PLUGIN_ROOT}/references/...` citation must now resolve inside the *new* plugin:

```bash
cd plugins/guideline-reviewers
miss=0
for pth in $(grep -ohE '\$\{CLAUDE_PLUGIN_ROOT\}/references/[A-Za-z0-9/._-]+' commands/*.md agents/*.md | sed 's|.*references/||' | sort -u); do
  [ -e "references/$pth" ] || { echo "MISSING: references/$pth"; miss=1; }
done
echo "unresolved=$miss"; cd ../..
```
Expected: `unresolved=0` and no `MISSING:` lines. A non-zero result means a citation points at a file left behind in `dev-workflows`, and the move is incomplete.

- [ ] **Step 8: Commit**

```bash
git add -A plugins/guideline-reviewers plugins/dev-workflows
git commit -m "refactor(guideline-reviewers): move the commands, agents and corpora

Two commands, two agents, two documentation pages and 38 reference files moved
with git mv so history follows them. Adds the agent and reference inventory
pages the gate requires in both directions.

dev-workflows' own documentation still claims what left, so the whole-tree gate
is red at this commit by design; the new plugin checked alone is green. The
reconciliation is the next commit, kept separate so the move can be reviewed
without the count churn on top of it."
```

---

### Task 5: Reconcile `dev-workflows` and release

**Files:**
- Modify: `plugins/dev-workflows/docs/README.md`, `plugins/dev-workflows/README.md`
- Modify: `plugins/dev-workflows/docs/reference/{agents.md,references.md}`
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
- Modify: `plugins/dev-workflows/CHANGELOG.md`, `CLAUDE.md`

**Interfaces:**
- Consumes: the moved tree from Task 4.
- Produces: `dev-workflows` at 26 commands, 36 agents, 67 reference files; version `3.25.0`.

- [ ] **Step 1: Get the exact failure list to work from**

```bash
./scripts/check-docs.sh --root . 2>&1 | grep -E '^(FAIL check|  )' | head -40
```
Expected: rows naming the two commands, the two agents, the two subtrees, and every prose count that changed. Work the list top to bottom; do not guess at what changed.

- [ ] **Step 2: Re-derive the counts from the tree, never from memory**

```bash
cd plugins/dev-workflows
echo "commands: $(ls commands/*.md|wc -l)  agents: $(ls agents/*.md|wc -l)  refs: $(find references -type f|wc -l)  docs: $(find docs -name '*.md'|wc -l)"
cd ../..
```
Expected: `commands: 26  agents: 36  refs: 67  docs: 41`.

- [ ] **Step 3: Remove the moved entries from dev-workflows' documentation**

Delete the two command rows from `plugins/dev-workflows/docs/README.md` (both the "I want to…" table row and the Commands list entries), the two agent rows from `docs/reference/agents.md`, and the `api-guidelines/` and `guidelines/` subtree rows from `docs/reference/references.md`. Then update the prose counts, using the Step 2 numbers. Check 9 gates count sentences; find them rather than recalling them:

```bash
grep -rlnE '(twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred)[a-z-]*' \
  plugins/dev-workflows/docs plugins/dev-workflows/README.md
```

Every hit is a candidate; the gate's own failure output from Step 1 names the ones that are actually wrong. `docs/reference/references.md` additionally carries a worked arithmetic paragraph whose sum must be re-derived, not patched.

Replace the guideline-review row in `plugins/dev-workflows/README.md`'s role table with a pointer:

```markdown
| Anytime — guideline review | Moved to the [`guideline-reviewers`](../guideline-reviewers/README.md) plugin | Review an OpenAPI spec or app UI against bundled guidelines. |
```

- [ ] **Step 4: Run the gates until green**

```bash
./scripts/check-docs.sh --root . ; echo "docs=$?"
./scripts/check-id-grammar.sh --root . >/dev/null; echo "id=$?"
python3 scripts/validate-catalog.py >/dev/null; echo "catalog=$?"
./scripts/check-docs.sh --selftest | tail -1
```
Expected: `docs=0`, `id=0`, `catalog=0`, `SELFTEST PASS`.

- [ ] **Step 5: Bump the version and write the changelog**

`dev-workflows` loses two commands, which breaks `/dev-workflows:guideline-reviewer` — a minor at plugin level per the spec's S8 reasoning applied to a partial move, since the bare names still resolve once the new plugin is installed. Set `plugins/dev-workflows/.claude-plugin/plugin.json` and its `marketplace.json` entry to `3.25.0`, and prepend to `plugins/dev-workflows/CHANGELOG.md`:

```markdown
## [3.25.0] — 2026-09-02

### Changed — the guideline reviewers moved to their own plugin

`/api-guideline-reviewer` and `/guideline-reviewer`, their two agents, and the 38 reference files they read now ship as **`guideline-reviewers`**. Install it with `claude plugin install guideline-reviewers@ihudak-plugins`; the bare command names keep working once it is installed, and only the namespaced form `/dev-workflows:guideline-reviewer` is gone.

They were the one part of this plugin that shared nothing with the rest: no shared reference, no shared agent, and not even model routing, which `CLAUDE.md` already exempted them from. They carried 38 of 105 reference files — 36% of the bundled weight — for two commands nothing else called.

This is the first increment of the marketplace split designed in `docs/superpowers/specs/2026-09-02-marketplace-split-design.md`. It deliberately proves the multi-plugin machinery — catalogue registration, a per-plugin documentation tree, and a gate that iterates plugins rather than assuming one — on the extraction that needs no dependency, no shared-reference loader and no citation rewrite. Those arrive with `workflows-core` in increment 2.
```

- [ ] **Step 6: Update CLAUDE.md's inventory and command list**

Change the "twenty-eight slash commands" sentence and the command enumeration to drop the two moved commands, and note that `guideline-reviewers` is a separate plugin. Re-derive against Step 2's numbers.

- [ ] **Step 7: Final verification, then commit**

```bash
./scripts/check-docs.sh --root . && ./scripts/check-id-grammar.sh --root . && python3 scripts/validate-catalog.py && ./scripts/check-docs.sh --selftest | tail -1
git add -A
git commit -m "docs(dev-workflows): reconcile inventories after the guideline move

26 commands, 36 agents, 67 reference files -- re-derived from the tree, not
carried over. Drops the two command pages, two agent rows and two reference
subtrees from dev-workflows' documentation, points its role table at the new
plugin, and updates every prose count check 9 gates.

3.25.0: the namespaced /dev-workflows:guideline-reviewer form is gone, while the
bare names keep working once guideline-reviewers is installed."
```

---

## Verification for the increment

Before opening the PR:

```bash
./scripts/check-docs.sh --root .
./scripts/check-id-grammar.sh --root .
python3 scripts/validate-catalog.py
./scripts/check-docs.sh --selftest | tail -1
PLUGIN_RELS="plugins/guideline-reviewers" ./scripts/check-docs.sh --root .
git log --oneline pre-split..HEAD
```

All four must pass, the single-plugin run must pass, and the log must show five commits — one per task, each green on its own except Task 4, which is red by design and made green by Task 5.

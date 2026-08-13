# `/document` Gate Enforcement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `/document`'s verification gates capable of running, impossible for the orchestrator to skip silently, and preceded by a Phase 0 preflight that stops a run started in a container without the required tools.

**Architecture:** Two new shared references define the contract — `toolchain-preflight.md` (what tools the run needs and what happens when they are absent) and `gate-ledger.md` (a six-outcome vocabulary with no orchestrator-assignable "skipped"). Four wiring repairs then make the gates functional: the linter ladder falls through instead of jumping, `changelog-guidelines.md` gains consumers in the write path, the repo's own pre-PR checklist is ingested rather than filtered out, and commands/CLI invocations become a verified claim class. `doc-reviewer` gains a Verification-gate integrity dimension and reads the ledger.

**Tech Stack:** Prompt and reference markdown, YAML profile files, JSON manifests. No build, no test framework — verification is grep and reading.

**Spec:** `docs/superpowers/specs/2026-08-08-document-gate-enforcement-design.md`

## Global Constraints

- **Versions:** canonical + mgd `dev-workflows` → **2.43.0**; copilot `dev-workflows` → **2.13.0**. Six locations must move in lockstep — three `plugin.json` and three marketplace catalogs.
- **Marketplace catalogs (missed in 2.42.0 — never omit again):** `ihudak-claude-plugins/.claude-plugin/marketplace.json`, `mgd-claude-plugins/.claude-plugin/marketplace.json`, `ihudak-copilot-plugins/.github/plugin/marketplace.json`. Each lists **four** plugins — edit only the `dev-workflows` entry, and update both its `version` **and** its `description` when behaviour changes.
- **Copilot's `.github/copilot-instructions.md` is the CLAUDE.md counterpart** and was also missed in 2.42.0. It is in scope for Task 12.
- **mgd identity files — NEVER `cp` these five:** `plugins/dev-workflows/.claude-plugin/plugin.json`, `README.md`, `LICENSE`, `references/dependencies.md`, `CHANGELOG.md`. Plus repo-root `CLAUDE.md` and `.claude-plugin/marketplace.json`. Post-port `diff -rq` must report those five and **nothing else**.
- **Citation idiom:** match the surrounding file's existing convention. Agents, skills, and reference bodies cite `${CLAUDE_PLUGIN_ROOT}/references/<file>.md`; `commands/document.md` already uses the same form throughout — follow it. Never introduce a new idiom, and never hardcode `~/.claude/plugins/data/...` paths.
- **Copilot adaptation:** `${CLAUDE_PLUGIN_ROOT}/references/X` → `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/X`; `Agent (subagent_type: "dev-workflows:X", model: …)` → `→ task(agent_type: "dev-workflows:X", model: …)`; agent frontmatter `tools: ["Read", "Glob"]` → `tools: [view, glob]` (lowercase, `view` = Read). No `${CLAUDE_PLUGIN_ROOT}` or `subagent_type` token may survive in a Copilot file.
- **Prose formatting:** per `references/prose-formatting.md`, content the plugin *generates* is never hard-wrapped. Plugin source files themselves follow their existing local wrapping — match each file you edit.
- **No behaviour outside the spec.** If a task's edit seems to require a change the spec does not describe, stop and report rather than inventing it.
- **Every `choices:` array ends with `"Other… (describe)"`** where applicable, per `references/escalation-rules.md`.

## File Structure

**New (canonical `plugins/dev-workflows/`):**

| File | Responsibility |
|---|---|
| `references/toolchain-preflight.md` | Derive the run's required tool set; the `toolchain` block; the tool→gate map; the missing-tool prompt |
| `references/gate-ledger.md` | Outcome vocabulary, row schema, `/document` gate registry, reviewer contract, adoption notes |
| `references/repo-verification-gates.md` | Find and extract the docs repo's own pre-PR checklist; the `repo_verification_gates` block; how each consumer applies it (planner in Jira mode, orchestrator in direct mode) |

**Modified (canonical):** `references/escalation-rules.md`, `references/source-truth.md`, `references/dynatrace-docs/render-verification.md`, `references/dynatrace-docs/docs-profile.default.yml`, `references/dynatrace-docs/docs-profile-schema.md`, `agents/docs-style-checker.md`, `agents/doc-planner.md`, `agents/doc-writer.md`, `agents/doc-reviewer.md`, `commands/document.md`, `commands/docs-profile.md`, `README.md`, `CHANGELOG.md`, `.claude-plugin/plugin.json`, repo-root `.claude-plugin/marketplace.json`, repo-root `CLAUDE.md`.

**Task → feature map:**

| Task | Spec section | Deliverable |
|---|---|---|
| 1 | §1, §2.1–2.3, §2.7, §2.2 | The two new references + the verbatim-choice-list rule |
| 2 | §5 (profile half) | `commands.per_space` in the default profile, schema, and `/docs-profile` |
| 3 | §1 | Phase 0 preflight, both modes |
| 4 | §3 | Linter ladder fall-through + space-aware lint |
| 5 | §2.4–2.6 | Ledger rows, Phase 9 table, reviewer contract, invariants |
| 6 | §7 | Render gate repair |
| 7 | §4 | `changelog-guidelines.md` wiring |
| 8 | §5 (checklist half) | `repo_verification_gates` |
| 9 | §6 | Commands/CLI claim class + supplementary grep |
| 10 | — | Canonical docs, version, catalog |
| 11 | — | Port to mgd |
| 12 | — | Port to copilot |

---

### Task 1: The contract references

**Files:**
- Create: `plugins/dev-workflows/references/gate-ledger.md`
- Create: `plugins/dev-workflows/references/toolchain-preflight.md`
- Create: `plugins/dev-workflows/references/repo-verification-gates.md`
- Modify: `plugins/dev-workflows/references/escalation-rules.md`

**Interfaces:**
- Consumes: nothing (first task).
- Produces: the outcome vocabulary `RAN | DEGRADED | FAILED | UNAVAILABLE | SKIPPED_BY_USER | NOT_APPLICABLE`; the gate ids `toolchain_preflight`, `source_truth_verification`, `style_check`, `repo_checklist`, `build_check`, `render_smoke_check`; the `gate_ledger:` row schema; the `toolchain:` block schema; the `repo_verification_gates:` block schema and its extraction procedure; and the rule name **"Choice lists are presented verbatim"** in `escalation-rules.md`. Tasks 3–9 cite these by name.

- [ ] **Step 1: Create `references/gate-ledger.md`**

Write this file exactly:

````markdown
# Gate ledger (shared)

Single source of truth for how a command records whether each of its verification gates actually ran.

Consumed by `/document` (both modes). Written generically so other commands can adopt it — see §6.

---

## 1. The problem it solves

A phase that says "Mandatory — never skip on your own judgement" is still skipped when the
orchestrator finds a plausible-sounding reason. `/document` Phase 6.4 has carried that exact wording
since v2.0.0 and was skipped anyway, and Phase 6.5's `(Recommended)` marker was moved onto the Skip
option on the same run. Emphasis is not enforcement.

The ledger removes the cell in which a run can write *"I decided this wasn't necessary."* Every gate
ends in one of six outcomes, and every non-run path terminates in a **named missing precondition**, a
**named missing tool**, or a **verbatim user decision**.

## 2. Outcomes

| Outcome | Means | Assignable by |
|---|---|---|
| `RAN` | The gate's primary mechanism executed. | evidence only |
| `DEGRADED` | Only a fallback executed. Records what did not run, why, and what CI will still check. | evidence only |
| `FAILED` | Ran and found blocking problems. Feeds the caller's existing fix loops. | evidence only |
| `UNAVAILABLE` | Nothing ran and no fallback exists, with the precondition met. **Not a resting state** — see §5. | the orchestrator, but never as a final answer |
| `SKIPPED_BY_USER` | The user chose to skip. Carries their decision quoted verbatim. | the user only |
| `NOT_APPLICABLE` | A named precondition is unmet. | evidence only |

There is no orchestrator-assignable "skipped". "Flaky, and the static analysis was sufficient" has
nowhere to go.

`DEGRADED` proceeds — a weaker check is not a documentation defect, and the final report names what
CI will check that the run did not. Total absence of coverage does not proceed.

## 3. Row schema

The ledger is an in-context YAML block. The orchestrator **appends a row at the moment each gate
completes** — never reconstructs the ledger at report time from memory.

```yaml
gate_ledger:
  - gate: <registry id from §4>
    phase: "<the phase that owns it>"
    outcome: RAN | DEGRADED | FAILED | UNAVAILABLE | SKIPPED_BY_USER | NOT_APPLICABLE
    mechanism: <what actually executed; omitted when nothing did>
    not_run:                                        # DEGRADED only, non-empty
      - mechanism: <the primary mechanism that did not run>
        reason:    <why>

    ci_still_checks: <one line>                     # DEGRADED only, non-empty
    precondition_unmet: <the named precondition>    # NOT_APPLICABLE only, non-empty
    user_decision: "<the user's choice, verbatim>"  # SKIPPED_BY_USER only, non-empty
    findings: <count>                               # RAN / DEGRADED / FAILED
```

## 4. The `/document` gate registry

| Gate id | Phase | Precondition | Primary | Fallback |
|---|---|---|---|---|
| `toolchain_preflight` | 0 | always (runs after profile resolution) | `command -v` / `test -d` over the required set (`toolchain-preflight.md` §2) | none |
| `source_truth_verification` | 5.8 | ≥1 entry in `code_repos` | claim-class verification per `source-truth.md` §2–§3 | one supplementary direct grep against the resolved local path |
| `style_check` | 6.4 | ≥1 file written | the repo linter ladder **plus** `dt-style-checker` complementary | `dt-style-checker` alone |
| `repo_checklist` | 6.4 | the repo publishes authoring/verification guidance | `repo_verification_gates` applied to the written files | none |
| `build_check` | 6.5 S1 | write context is a buildable repo | `commands.per_space.<space>.build` per written space, else whole-repo `commands.build` | the Step 2 dev-server boot |
| `render_smoke_check` | 6.5 S2 | buildable repo with ≥1 affected page | dev servers for the target **and** protected spaces | the manual pages-to-visit table |

A gate whose precondition is unmet records `NOT_APPLICABLE` with the precondition named. It is never
silently absent from the ledger.

**Direct mode** (`/document` Mode B) registers exactly three gates: `toolchain_preflight` (Phase 0),
`repo_checklist` (Phase 0 extraction, checked at Phase 3.5), and `style_check` (Phase 3.5). The other
three ids never appear in a direct-mode ledger — not even as `NOT_APPLICABLE`:

- `source_truth_verification` — direct mode has no Phase 5.8, no `jira-reader`, and no `code_repos`.
- `build_check` and `render_smoke_check` — direct mode has no Phase 6.5 and no `target_spaces`.

Direct mode has no `doc-planner`, so its orchestrator extracts `repo_verification_gates` itself per
`${CLAUDE_PLUGIN_ROOT}/references/repo-verification-gates.md` §5.

## 5. Converting `UNAVAILABLE`

`UNAVAILABLE` means the precondition was met and neither the primary nor the fallback ran — a real
coverage hole. The orchestrator converts it before the run continues, with a choice list bound by the
"Choice lists are presented verbatim" rule in `escalation-rules.md`:

```
choices: ["Install <named tool> and retry this gate", "Proceed without this check — record my decision", "Cancel the run", "Other… (describe)"]
```

- "Install and retry" → re-run the gate and rewrite its row.
- "Proceed without this check" → rewrite the row as `SKIPPED_BY_USER` with the user's choice quoted
  verbatim in `user_decision`.
- "Cancel the run" → stop.

The orchestrator never selects among these on the user's behalf.

## 6. The reviewer contract

The caller passes the completed `gate_ledger` to its review gate. For `/document` that is
`doc-reviewer`'s **Verification-gate integrity** dimension. The reviewer raises a **BLOCKER** when any
of these holds:

- a registry gate has **no row** in the ledger;
- a row's outcome is `UNAVAILABLE` (§5 never converted it);
- `SKIPPED_BY_USER` with an empty or absent `user_decision`;
- `NOT_APPLICABLE` with an empty or absent `precondition_unmet`;
- `DEGRADED` with an empty `not_run` or an empty `ci_still_checks`.

`DEGRADED` is otherwise not a finding — the reviewer notes it, and the final report prints its
`ci_still_checks` line.

## 7. Adopting this in another command

A command adopting the ledger declares its own registry table in the shape of §4 (gate id, phase,
precondition, primary, fallback), appends rows per §3, converts `UNAVAILABLE` per §5, and passes the
block to its review gate with the §6 contract. Nothing in §2, §3, or §5 is `/document`-specific.

## 8. Hard rules

- NEVER write a ledger row from memory at report time. Append it when the gate completes.
- NEVER record an outcome the evidence does not support — a gate that did not execute is not `RAN`.
- NEVER leave `UNAVAILABLE` as a final outcome; §5 always converts it.
- NEVER paraphrase the user's words in `user_decision`; quote the option they chose.
- NEVER omit a registry gate's row because it seemed irrelevant — record `NOT_APPLICABLE` and name the
  precondition.
- NEVER promote `DEGRADED` to a finding on its own; the reviewer's §6 list is exhaustive.
````

- [ ] **Step 2: Create `references/toolchain-preflight.md`**

Write this file exactly:

````markdown
# Toolchain preflight (shared)

Single source of truth for verifying, before a run writes anything, that the tools its gates invoke
are actually present.

Consumed by `/document` (both modes) at Phase 0. Pairs with
`${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` — the preflight decides whether to start; the ledger
records what actually happened.

---

## 1. Why this runs first

A `/document` run started in a container without `vale` and without `pnpm` still produces a branch, a
commit, and a PR draft. No linter ran and no server booted, so the documentation is worse — but the PR
exists and CI is green, and nothing signals that anything went wrong. The failure is silent, and it is
the run's own environment that caused it.

That is knowable at Phase 0 for the cost of one `command -v` per tool. Without a preflight the run
discovers it one gate at a time, at Phase 6.4 and Phase 6.5, after the documentation is written.

## 2. Deriving the required set

Run this **after profile resolution** — the profile is what names the commands. Union three sources;
de-duplicate by binary name.

1. **The resolved profile.** Take the **first whitespace-separated token** of every `commands.*` value
   (including every `commands.per_space.<space>.*` value) and every `dev_servers.servers[].command`.
   `"pnpm dynatrace:lint"` ⇒ `pnpm`. Add every entry in `profile.prerequisites` as a named
   prerequisite (these are prose, not binaries — record them for reporting, and check them only when
   the prose names a checkable path or binary).
2. **Repo config signals**, checked at `repo_root`:

   | Signal file | Implies |
   |---|---|
   | `.vale.ini` | `vale` |
   | `pnpm-lock.yaml` | `pnpm` |
   | `package-lock.json` | `npm` |
   | `yarn.lock` | `yarn` |
   | `.markdownlint.json` / `.markdownlint.jsonc` | `markdownlint` |
   | `.remarkrc*` | `remark` |

   Separately, when any lockfile is present, check `node_modules/` as an **installed-dependencies**
   signal. A present `pnpm` with absent dependencies fails just as completely as a missing `pnpm`.
3. **The repo's documented prerequisites.** Grep `repo_root`'s `CONTRIBUTING.md`, `CONTRIBUTION.md`,
   and `README.md` for a heading matching `Prerequisites` (case-insensitive) and read that section.
   Best-effort: extract named tools and minimum versions where stated. Nothing found ⇒ contribute
   nothing. Never fail the preflight on an unparseable Prerequisites section.

**Direct mode has no profile.** `/document` Mode B resolves `repo_root` as cwd's git root and uses
sources **2 and 3 only**. Source 1 contributes nothing there.

## 3. Checking

- Binaries: `command -v <binary>` — present when exit 0.
- Directory signals (`node_modules/`): `test -d`.
- Never install anything. Never modify the repo. This step is read-only.

## 4. The `toolchain` block

```yaml
toolchain:
  - tool: <binary name, or a directory signal such as "node_modules">
    status: present | missing
    source: <profile.commands | profile.prerequisites | .vale.ini | pnpm-lock.yaml | CONTRIBUTING.md Prerequisites | …>
    required_by: [<gate ids from gate-ledger.md §4>]
```

`required_by` maps each tool onto the gates it powers, which is what lets the preflight state the
run's outcome before the run:

| Tool | Typically required by |
|---|---|
| the repo's prose linter (`vale`, `markdownlint`, `remark`) | `style_check` |
| the package manager (`pnpm` / `npm` / `yarn`) | `style_check`, `build_check`, `render_smoke_check` |
| `node_modules` present | every gate the package manager powers |
| `git` | `source_truth_verification` |

Derive `required_by` from where the tool came from: a binary that appears only in
`commands.per_space.<space>.build` powers `build_check`; one that appears in a `dev_servers` command
powers `render_smoke_check`. A tool with an empty `required_by` is reported but never blocks.

## 5. Reporting and the prompt

**When every required tool is present, say nothing beyond one line in the caller's readiness output.**
A preflight that prompts on a healthy container becomes one more thing to click through, and dies the
way the Phase 6.4 gate died.

When one or more required tools are **missing**, print the `toolchain` rows (missing first), then the
consequence — each affected gate and the outcome it will record — then ask:

```
choices: ["Cancel — re-run in the docs container (Recommended)", "Continue anyway — record the degraded gates", "Other… (describe)"]
```

Example consequence line:

> With `vale` and `pnpm` missing, this run would record `style_check` **DEGRADED** (only
> `dt-style-checker` runs — the repo's own linter, the one CI will run on your PR, would not),
> `build_check` **UNAVAILABLE**, and `render_smoke_check` **UNAVAILABLE**.

- **"Cancel"** → stop the run. Nothing has been written.
- **"Continue anyway"** → for each gate named in the consequence line, **pre-seed** its ledger row's
  expected outcome and carry the user's choice verbatim, so that when the gate is reached its row
  records `SKIPPED_BY_USER` (or `DEGRADED` where a fallback does run) with `user_decision` already
  attributed. A pre-seeded row is still overwritten by what actually happens — a tool that turns out
  to work records `RAN`.

The preflight is itself a ledger gate: `toolchain_preflight`, phase 0, no fallback. Record its own row
(`RAN` when the check completed, whatever the findings; `FAILED` only if the check itself could not be
performed).

## 6. Location reporting

The caller has already resolved its target repo. The preflight does not re-resolve it — it reports
`repo_root`, and when `repo_root` differs from cwd it says so on its own line. **A divergence by
itself never prompts**: writing into `${DOCS_PATH:-/workspace/docs}` from a different working
directory is the normal AI-container case.

## 7. Hard rules

- NEVER install, upgrade, or configure a tool. Report and ask.
- NEVER modify any file under `repo_root`.
- NEVER prompt when every required tool is present.
- NEVER move the `(Recommended)` marker off "Cancel" in §5 — the "Choice lists are presented verbatim"
  rule in `escalation-rules.md` binds this prompt.
- NEVER fail the run because a `Prerequisites` section could not be parsed; source 3 is best-effort.
- NEVER treat a tool with an empty `required_by` as blocking.
````

- [ ] **Step 2b: Create `references/repo-verification-gates.md`**

Write this file exactly:

````markdown
# Repo verification gates (shared)

Single source of truth for extracting a documentation repository's **own** pre-PR checklist and
applying it to the files a run just wrote.

Consumed by `doc-planner` (`/document` Jira mode) and by `/document` Mode B directly — direct mode has
no planner, so its orchestrator performs the extraction itself. Both produce the same block, and both
feed the `repo_checklist` gate in `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md`.

---

## 1. Why

A docs repo publishes the checks a human reviewer applies before merging. `dynatrace-docs` puts them
in `CONTRIBUTING.md` under `## PR checklist` — a Contributors minimum check and an InfoDevs advanced
check covering frontmatter fields, changelog conformance, sensitive information, duplicate headings,
terminology, and "Validate the change. The validation must pass with no errors or warnings."

Those are exactly the checks a generated PR should already satisfy. Consuming them is not optional
politeness: a run that ignores them ships work a reviewer will bounce.

## 2. Finding the checklist

Scan the repo root (and `.claude/`) for `CONTRIBUTING.md`, `CONTRIBUTION.md`, `README.md`,
`CLAUDE.md`, `STYLE.md`, and `DOCUMENTATION-GUIDELINES.md`. In each, look for a checklist section —
headings matching, case-insensitively, `PR checklist`, `Before you submit`, `Before submitting`,
`Definition of done`, `Review checklist`, `Submission checklist`, or `Merge checklist`. Read every
sub-section beneath it.

Nothing found ⇒ emit `repo_verification_gates: []`. That is a normal outcome, not an error.

## 3. What to extract

Include an item when it is **checkable against the files this run wrote**:

| Kind | Examples |
|---|---|
| `frontmatter` | required fields present; `description` meets the repo's guidelines; `changelog` present and conforming |
| `content` | no sensitive information (hostnames, IP addresses, API tokens); no placeholder text left behind |
| `structure` | no duplicate headings; no walls of text; images referenced the way the repo requires |
| `terminology` | product names spelled and capitalised per the repo's list |
| `validation` | "run a local build and check the local preview"; "run source validation"; "the validation must pass with no errors or warnings" |

Exclude anything that is not about the written files: PR title conventions, reviewer assignment,
branch mechanics, ticket hygiene, release timing.

## 4. The block

```yaml
repo_verification_gates:        # [] when the repo publishes no checklist
  - check:  <one checkable requirement, phrased as a testable assertion>
    source: <file + section, e.g. "CONTRIBUTING.md § PR checklist → Advanced check (InfoDevs)">
    kind:   frontmatter | content | structure | terminology | validation
```

## 5. Applying it

- **`/document` Jira mode** — `doc-planner` emits the block during its guidance scan; `doc-reviewer`
  holds the written files against each entry; `/document` Phase 6.4 records the `repo_checklist`
  ledger row.
- **`/document` direct mode** — there is no planner. The orchestrator extracts the block itself at
  Phase 0, in the same pass that reads the repo's `Prerequisites` for
  `${CLAUDE_PLUGIN_ROOT}/references/toolchain-preflight.md` §2 source 3, checks the edited files
  against it at Phase 3.5, and records the `repo_checklist` row there.

A `validation`-kind entry is **not** satisfied by reading files — it names a command the run must
actually have executed. Whether it ran is the business of the `style_check` / `build_check` ledger
rows. Record it in the block so a reviewer can see it was required, and let the ledger carry whether
it happened.

## 6. Hard rules

- NEVER emit an entry that cannot be checked against the files this run wrote.
- NEVER paraphrase a repo rule into a different requirement. Quote or tightly restate the repo's own
  wording, and always name its `source` file and section — a consumer must be able to cite it.
- These gates **augment, never override** the plugin's built-in references. Where one conflicts with a
  built-in rule, record both and note the conflict; never silently pick a winner.
- NEVER treat an empty block as a failure. A repo without a checklist is normal.
````

- [ ] **Step 3: Add the verbatim-choice-list rule to `references/escalation-rules.md`**

Insert this section immediately after the intro paragraph that ends `…both variants are listed.` and before `## Jira key dir not found`:

```markdown
## Choice lists are presented verbatim

**A choice list written into a command phase is presented to the user verbatim. Its options, their
order, their wording, and the `(Recommended)` marker are not the orchestrator's to change. An
orchestrator that believes a different option is correct for this run says so in prose alongside the
list — it never edits the list.**

This rule binds every command in the plugin, not only the ones documented below. It exists because a
`/document` run presented Phase 6.5's `["Run smoke-check (Recommended)", "Skip — use the manual table
only", "Cancel"]` with the recommendation moved onto Skip, and the render gate was never exercised.

Adding the trailing `"Other… (describe)"` entry where a phase omits it is the one permitted
adjustment.
```

- [ ] **Step 4: Verify the three files**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
test -f references/gate-ledger.md && test -f references/toolchain-preflight.md && test -f references/repo-verification-gates.md && echo "all three created"
grep -c "SKIPPED_BY_USER" references/gate-ledger.md
grep -n "Choice lists are presented verbatim" references/escalation-rules.md
grep -rn 'plugins/data\|~/.claude/plugins' references/gate-ledger.md references/toolchain-preflight.md references/repo-verification-gates.md || echo "no hardcoded plugin paths — good"
echo "--- direct mode registers exactly 3 and names the 3 exclusions ---"
grep -c "registers exactly three gates" references/gate-ledger.md
grep -c "repo-verification-gates.md" references/gate-ledger.md
```
Expected: `all three created`; a count ≥ 4 for `SKIPPED_BY_USER`; one heading match in `escalation-rules.md`; the "no hardcoded plugin paths" line; then `1` and `1`.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/gate-ledger.md plugins/dev-workflows/references/toolchain-preflight.md plugins/dev-workflows/references/escalation-rules.md
git commit -m "feat(dev-workflows): add gate-ledger and toolchain-preflight references

Defines the six-outcome gate vocabulary with no orchestrator-assignable
skip, the /document gate registry, the reviewer contract, and the Phase 0
toolchain preflight. Adds the verbatim-choice-list rule to
escalation-rules.md, which binds every command.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 2: Per-space profile commands

**Files:**
- Modify: `plugins/dev-workflows/references/dynatrace-docs/docs-profile.default.yml`
- Modify: `plugins/dev-workflows/references/dynatrace-docs/docs-profile-schema.md`
- Modify: `plugins/dev-workflows/commands/docs-profile.md`

**Interfaces:**
- Consumes: nothing.
- Produces: `commands.per_space.<space id>.{lint,build}` — an optional map keyed by space id. Task 3 reads it to derive required tools, Task 4 reads `per_space.<space>.lint`, Task 6 reads `per_space.<space>.build`.

**Context:** `/workspace/docs/package.json` defines `dynatrace:lint`, `managed:lint`, `dynatrace:build`, `managed:build`, `dynatrace:start`, `managed:start`. The built-in profile knows only `pnpm dynatrace:lint` and no build command at all, which is why Phase 6.5's gating build check never fires and a Managed-only run is linted by the SaaS linter.

- [ ] **Step 1: Add `per_space` to `docs-profile.default.yml`**

Replace this block:

```yaml
commands:
  lint: "pnpm dynatrace:lint"
  format: "pnpm prettier -w"
  commit_hook: "husky pre-commit -> lint-staged -> pnpm prettier -w"
```

with:

```yaml
commands:
  lint: "pnpm dynatrace:lint"
  format: "pnpm prettier -w"
  commit_hook: "husky pre-commit -> lint-staged -> pnpm prettier -w"
  per_space:
    saas:
      lint: "pnpm dynatrace:lint"
      build: "pnpm dynatrace:build"
      format: "pnpm dynatrace:format"
    managed:
      lint: "pnpm managed:lint"
      build: "pnpm managed:build"
      format: "pnpm managed:format"
```

- [ ] **Step 2: Add the lint prerequisite to `docs-profile.default.yml`**

Replace:

```yaml
prerequisites:
  - "a dev server may need a working .docstack toolchain (e.g. an axios>=1.16 shim) before `*:start` boots"
```

with:

```yaml
prerequisites:
  - "a dev server may need a working .docstack toolchain (e.g. an axios>=1.16 shim) before `*:start` boots"
  - "the lint command needs a build folder: run a `*:start` (serve) once in a fresh clone before the first `*:lint`, or lint exits non-zero with no content findings (CONTRIBUTING.md, 'Other useful scripts/tasks')"
```

- [ ] **Step 3: Document `per_space` in `docs-profile-schema.md`**

In the example block, replace:

```yaml
commands:
  lint: "pnpm dynatrace:lint"
  format: "pnpm prettier -w"
  commit_hook: "husky pre-commit -> lint-staged -> pnpm prettier -w"
```

with:

```yaml
commands:
  lint: "pnpm dynatrace:lint"
  format: "pnpm prettier -w"
  commit_hook: "husky pre-commit -> lint-staged -> pnpm prettier -w"
  per_space:                          # optional; keyed by space id from spaces[]
    saas:
      lint: "pnpm dynatrace:lint"
      build: "pnpm dynatrace:build"
      format: "pnpm dynatrace:format"
    managed:
      lint: "pnpm managed:lint"
      build: "pnpm managed:build"
      format: "pnpm managed:format"
```

Then, in the `## Field rules` list, insert after the `dev_servers.readiness_timeout_seconds` bullet:

```markdown
- `commands.per_space` is optional — a map keyed by a space id from `spaces[]`, each entry carrying any of `lint`, `build`, `format`. A multi-space repo that lints or builds each space separately declares it here; consumers run the command for each space actually written to and fall back to the flat `commands.lint` / `commands.build` when the map is absent. A space id in `per_space` that is not in `spaces[]` is a profile error.
- `commands.build` (flat) and `commands.per_space.<space>.build` are both optional. When neither exists, the consumer treats the dev-server boot as the build proof. Declare a build command whenever the repo has one — an absent build command disables `/document`'s gating build check.
```

- [ ] **Step 4: Teach `/docs-profile` to detect `per_space`**

In `commands/docs-profile.md`, find the profile-authoring instruction block containing the line beginning `> - \`frontmatter:\` is **POINTERS ONLY**` (around line 115) and insert immediately before it:

```markdown
  > - `commands.per_space:` — when `package.json` (or the repo's task runner) exposes **per-space** lint / build / format scripts whose names correspond to entries in `spaces[]` (e.g. `dynatrace:lint` + `managed:lint` for spaces `saas` + `managed`), record them under `commands.per_space.<space id>`. Map the script name to the space id by the space's `content_root` (`dynatrace/_content` ⇒ script prefix `dynatrace`), never by guessing. Omit `per_space` entirely for a single-space repo, or when only whole-repo scripts exist.
```

- [ ] **Step 5: Verify against the real repo**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
python3 -c "
import yaml
p = yaml.safe_load(open('references/dynatrace-docs/docs-profile.default.yml'))
ps = p['commands']['per_space']
space_ids = {s['id'] for s in p['spaces']}
assert set(ps) <= space_ids, ('unknown space id', set(ps) - space_ids)
import json
scripts = set(json.load(open('/workspace/docs/package.json'))['scripts'])
for space, cmds in ps.items():
    for kind, cmd in cmds.items():
        script = cmd.split(' ', 1)[1]
        assert script in scripts, (space, kind, script, 'not in package.json')
print('per_space verified against /workspace/docs/package.json:', sorted(ps))
"
grep -c "per_space" references/dynatrace-docs/docs-profile-schema.md commands/docs-profile.md
```
Expected: `per_space verified against …: ['managed', 'saas']`, and a non-zero count in both files.

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/dynatrace-docs/docs-profile.default.yml plugins/dev-workflows/references/dynatrace-docs/docs-profile-schema.md plugins/dev-workflows/commands/docs-profile.md
git commit -m "feat(dev-workflows): per-space lint/build commands in the docs profile

dynatrace-docs defines dynatrace:lint, managed:lint, dynatrace:build and
managed:build, but the built-in profile knew only 'pnpm dynatrace:lint'
and no build command — so a Managed-only run was linted by the SaaS
linter and Phase 6.5's gating build check never fired.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 3: Phase 0 toolchain preflight

**Files:**
- Modify: `plugins/dev-workflows/commands/document.md` — Jira mode Phase 0 (new step 9, before `### Readiness`), the `### Readiness` table, and Mode B `## Phase 0 — Load the description`

**Interfaces:**
- Consumes: `references/toolchain-preflight.md` (Task 1) — the `toolchain:` block and the §5 prompt; `references/gate-ledger.md` (Task 1) — the row schema and the `toolchain_preflight` gate id; `references/repo-verification-gates.md` (Task 1) — the extraction procedure for direct mode; `commands.per_space` (Task 2) — a source of required binaries.
- Produces: the `toolchain` block, the initialized `gate_ledger` block with its first row, direct mode's `repo_verification_gates` block, and (on "Continue anyway") pre-seeded rows carrying `user_decision`. Task 5 appends the remaining rows to the same block.

- [ ] **Step 1: Add Phase 0 step 9 (Jira mode)**

In `commands/document.md`, insert immediately before the `### Readiness` heading:

```markdown
9. **Toolchain preflight.** Execute `${CLAUDE_PLUGIN_ROOT}/references/toolchain-preflight.md` against
   the resolved `docs_repo_path` and the profile loaded in step 4. Derive the required set from all
   three sources (profile commands including `commands.per_space`, repo config signals, the repo's
   documented `Prerequisites`), check each, and build the `toolchain` block.

   Initialize the run's `gate_ledger` (schema:
   `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §3) and append its first row:

   ```yaml
   gate_ledger:
     - gate: toolchain_preflight
       phase: "0"
       outcome: RAN
       mechanism: command -v / test -d over the derived required set
       findings: <count of tools with status: missing>
   ```

   - **Every required tool present** → record the row, contribute one line to the Readiness table, and
     proceed. Do NOT prompt.
   - **One or more missing** → present the `toolchain-preflight.md` §5 report and its choice list
     **verbatim** (the "Choice lists are presented verbatim" rule in
     `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` binds this prompt — `(Recommended)` stays
     on "Cancel"). On "Cancel", stop with the named error
     `TOOLCHAIN_UNAVAILABLE: <comma-separated missing tools> not available in this environment.` On
     "Continue anyway", pre-seed the affected gates' rows per `toolchain-preflight.md` §5 with the
     user's choice quoted verbatim in `user_decision`, and proceed.

   When the write context resolved in step 6 is `obsidian` or `plain_dir`, the build and render gates
   have no precondition to meet — do not name them in the consequence line, and let Phase 6.5 record
   their `NOT_APPLICABLE` rows as usual.
```

- [ ] **Step 2: Add the Readiness row**

In the `### Readiness` table, insert this row immediately after the `| Profile |` row:

```markdown
| Toolchain | `<all required tools present>` OR `<N missing: vale, pnpm — user chose to continue>`; writing into `<docs_repo_path>`[ (cwd is `<cwd>`)] |
```

- [ ] **Step 3: Add the Mode B preflight**

In `commands/document.md`, replace the whole Mode B Phase 0 section:

```markdown
## Phase 0 — Load the description

If `@file` syntax: read the file, confirm `"Loaded prompt from <filename.md> (N lines)."`, note any embedded images as "referenced image: <path>". Otherwise use the inline text verbatim.
```

with:

```markdown
## Phase 0 — Load the description

1. If `@file` syntax: read the file, confirm `"Loaded prompt from <filename.md> (N lines)."`, note any embedded images as "referenced image: <path>". Otherwise use the inline text verbatim.

2. **Toolchain preflight.** Resolve `repo_root` = `git rev-parse --show-toplevel` from cwd (when cwd is not a git tree, skip this step entirely — there is no repo to lint). Then execute
   `${CLAUDE_PLUGIN_ROOT}/references/toolchain-preflight.md` against it. Direct mode has no profile, so
   use **sources 2 and 3 only** (repo config signals and the repo's documented `Prerequisites`); the
   only gate in scope is `style_check`, so `required_by` never names `build_check` or
   `render_smoke_check`.

   Initialize `gate_ledger` and append the `toolchain_preflight` row per
   `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §3. Present the §5 prompt verbatim only when a
   required tool is missing; on "Cancel", stop with `TOOLCHAIN_UNAVAILABLE: <missing tools> not
   available in this environment.`

3. **Extract the repo's pre-PR checklist.** Direct mode has no `doc-planner`, so the orchestrator does
   this itself. In the **same pass** that read the repo's guidance files for step 2's `Prerequisites`,
   follow `${CLAUDE_PLUGIN_ROOT}/references/repo-verification-gates.md` §2–§4 and build the
   `repo_verification_gates` block. Carry it to Phase 3.5, which checks the edited files against it and
   records the `repo_checklist` ledger row. An empty block is normal — record it and move on. Skip this
   step entirely when cwd is not a git tree (step 2 already skipped for the same reason).
```

- [ ] **Step 4: Verify**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -n "toolchain-preflight.md" commands/document.md
grep -n "TOOLCHAIN_UNAVAILABLE" commands/document.md
grep -n "^| Toolchain |" commands/document.md
awk '/^## Phase 0 — Load and dispatch/,/^### Readiness/' commands/document.md | grep -n "^9\. \*\*Toolchain preflight"
```
Expected: two `toolchain-preflight.md` citations (one per mode); two `TOOLCHAIN_UNAVAILABLE` occurrences; one Readiness row; and step 9 found inside Jira-mode Phase 0 — confirming it lands after profile resolution (step 4) and before `### Readiness`.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/document.md
git commit -m "feat(dev-workflows): Phase 0 toolchain preflight in /document (both modes)

Checks the tools the run's gates invoke before anything is written, and
offers to stop when they are absent. Jira mode derives the required set
from the resolved profile plus repo signals plus the repo's documented
prerequisites; direct mode has no profile and uses the latter two.
Initializes the run's gate ledger with its first row.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 4: Linter ladder fall-through and space-aware lint

**Files:**
- Modify: `plugins/dev-workflows/agents/docs-style-checker.md`
- Modify: `plugins/dev-workflows/commands/document.md` — Phase 6.4 dispatch, Mode B Phase 3.5 dispatch

**Interfaces:**
- Consumes: `commands.per_space.<space>.lint` (Task 2).
- Produces: `docs-style-checker`'s new optional input `spaces: [{id, content_root, lint}]`, and its new output field `primary_attempts: [{linter, outcome, reason}]`. Task 5 reads `primary_attempts` to fill the `style_check` ledger row's `not_run` and `ci_still_checks`.

**Context:** the current detection order sends every step-1/2/3 failure to **step 5**, so a detected-but-broken rung abandons every rung below it. On `dynatrace-docs` that means `.vale.ini` claims the run, `vale` is not on PATH, and `pnpm dynatrace:lint` is never attempted.

- [ ] **Step 1: Add the `spaces` input**

In `agents/docs-style-checker.md`, replace the `## Inputs` code block:

```yaml
repo_root: <absolute path to the docs repo root>
files:     [<absolute paths of files written in Phase 6.3 (or Phase 3 for direct mode)>]
```

with:

```yaml
repo_root: <absolute path to the docs repo root>
files:     [<absolute paths of files written in Phase 6.3 (or Phase 3 for direct mode)>]
spaces:    # OPTIONAL. Supplied by the caller from profile.spaces + profile.commands.per_space.
  - id:           <space id>
    content_root: <path relative to repo_root, e.g. managed/_content>
    lint:         <the space's lint command, e.g. "pnpm managed:lint">
```

Immediately after that block, replace:

```markdown
Refuse to run without `repo_root` and at least one entry in `files`.
```

with:

```markdown
Refuse to run without `repo_root` and at least one entry in `files`. `spaces` is optional: when absent
or empty, run the whole-repo detection ladder below unchanged.
```

- [ ] **Step 2: Replace the hard rule that causes the jump**

Replace:

```markdown
> **Hard rule before anything else:** if a detected primary linter ERRORS at runtime (missing binary, non-zero exit with no parseable output, timeout), the agent MUST attempt the `dt-style-checker` pass (step 5) before returning `status: ERROR`. "Some check is better than no check." Only return `ERROR` if the primary linter AND `dt-style-checker` both fail or are unavailable.
```

with:

```markdown
> **Hard rule before anything else — this is a ladder, not a first-match switch.** A failure at step
> *N* continues to step *N+1*. The first step that **succeeds** sets `primary_linter`; a step that is
> detected but fails (missing binary, non-zero exit with no parseable output, timeout) is recorded in
> `primary_attempts` and the ladder moves on. Step 5 (`dt-style-checker`) is reached after steps 1–4
> have each been tried — never as an escape hatch from the first one. Only return `ERROR` if every
> primary rung AND `dt-style-checker` fail or are unavailable.
>
> This matters concretely: `dynatrace-docs` has both a `.vale.ini` (step 1) and `pnpm dynatrace:lint`
> / `pnpm managed:lint` scripts (step 2). When `vale` is not installed, step 2 is the linter CI will
> actually run, and abandoning it because step 1 was *detected* leaves the run with no repo linter at
> all.
```

- [ ] **Step 3: Rewrite the three fall-through markers**

Replace, in step 1:
```markdown
**On non-zero exit / missing binary → go to step 5 (dt-style-checker as fallback), not ERROR.**
```
with:
```markdown
**On non-zero exit / missing binary → record the attempt in `primary_attempts` and continue to step 2.**
```

Replace, in step 2:
```markdown
**On failure → go to step 5, not ERROR.**
```
with:
```markdown
**On failure → record the attempt in `primary_attempts` and continue to step 3.**
```

Replace, in step 3:
```markdown
**On failure → go to step 5, not ERROR.**
```
with:
```markdown
**On failure → record the attempt in `primary_attempts` and continue to step 4.**
```

- [ ] **Step 4: Make step 2 space-aware**

Replace step 2's opening sentence:

```markdown
2. **Project-specific lint script** — if `<repo_root>/package.json` has a script matching `*:lint` or `lint:*` that covers markdown (e.g. `docs:lint`, `site:lint`, `lint:md`), run it.
```

with:

```markdown
2. **Project-specific lint script** — when the caller supplied `spaces`, determine which spaces own the input `files` by matching each file's path against each space's `content_root` prefix, and run **that space's `lint` command** for every space owning at least one file (a Managed-only file set runs `pnpm managed:lint`, not the SaaS linter). Record one `primary_attempts` entry per space-scoped command. When `spaces` is absent or no space matches, fall back to the whole-repo behaviour: if `<repo_root>/package.json` has a script matching `*:lint` or `lint:*` that covers markdown (e.g. `docs:lint`, `site:lint`, `lint:md`), run it.
```

- [ ] **Step 5: Add `primary_attempts` to the output**

In the `## Output` block, insert immediately after the `primary_command:` line:

```yaml
primary_attempts:      # every primary rung tried, in ladder order; [] only when step 1 succeeded first try
  - linter: vale | yarn:<script> | npm:<script> | markdownlint | remark
    outcome: succeeded | failed | not_detected
    reason:  <one line; null when outcome == succeeded>
```

Then, in the `## Hard rules` list, insert after the `NEVER fabricate a primary_command` bullet:

```markdown
- NEVER return a `primary_attempts` list that omits a rung the ladder tried. It is the caller's only evidence for what CI will check that this run did not, and it fills the gate ledger's `not_run` and `ci_still_checks` fields.
- NEVER stop the ladder at a *detected but failing* rung. Detection is not execution — only a rung that produced parseable output counts as the primary pass.
```

- [ ] **Step 6: Pass `spaces` from Phase 6.4**

In `commands/document.md` Phase 6.4, replace the dispatch body:

```markdown
  > "Run the style check for this brief:
  >
  > repo_root: [the resolved docs_repo_path (Phase 0)]
  > files:     [absolute paths of every file written or modified in Phase 6.3]"
```

with:

```markdown
  > "Run the style check for this brief:
  >
  > repo_root: [the resolved docs_repo_path (Phase 0)]
  > files:     [absolute paths of every file written or modified in Phase 6.3]
  > spaces:    [one entry per space in profile.spaces that has a profile.commands.per_space entry — {id, content_root, lint}; omit the key entirely when the profile declares no per_space commands]"
```

- [ ] **Step 7: Note the ladder in Mode B Phase 3.5**

In Mode B Phase 3.5, replace:

```markdown
Never skip this phase on your own judgement of which linters are installed. `docs-style-checker` runs the chain internally: the primary linter PLUS `dt-style-checker` as a complementary semantic pass when the `dt-style-guide` plugin is installed (and as the fallback when the primary linter fails) — so the semantic / cross-page class is never silently dropped just because Vale exists.
```

with:

```markdown
Never skip this phase on your own judgement of which linters are installed. `docs-style-checker` runs the chain internally as a **ladder**: each primary rung is tried in turn (a detected-but-broken rung does not abandon the ones below it), and `dt-style-checker` runs as a complementary semantic pass whenever the `dt-style-guide` plugin is installed — so neither the repo's own linter nor the semantic / cross-page class is silently dropped. Record the returned `primary_attempts` in the `style_check` ledger row.

After the style check, hold the edited files against the `repo_verification_gates` block extracted in Phase 0 (`${CLAUDE_PLUGIN_ROOT}/references/repo-verification-gates.md` §5) and append the `repo_checklist` ledger row: `RAN` with `findings:` = the number of entries that failed, or `NOT_APPLICABLE` with `precondition_unmet: "the repo publishes no pre-PR checklist"` when the block is empty. Report any failed entry to the user with its `source` citation — direct mode has no reviewer gate, so this is where the repo's own rules surface.
```

- [ ] **Step 8: Verify**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
echo "--- no step-5 jumps remain (expect 0) ---"
grep -c "go to step 5" agents/docs-style-checker.md
echo "--- ladder continuations (expect 3) ---"
grep -c "continue to step" agents/docs-style-checker.md
echo "--- primary_attempts wired (expect >=4) ---"
grep -c "primary_attempts" agents/docs-style-checker.md
echo "--- spaces input reaches the agent (expect 1 in the command) ---"
grep -c "profile.commands.per_space entry" commands/document.md
```
Expected: `0`, `3`, a count ≥ 4, and `1`.

- [ ] **Step 9: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/docs-style-checker.md plugins/dev-workflows/commands/document.md
git commit -m "fix(dev-workflows): docs-style-checker falls through the ladder

A failure at any primary rung now continues to the next rung instead of
jumping to dt-style-checker, so a detected-but-broken .vale.ini no longer
abandons 'pnpm dynatrace:lint' — the linter CI actually runs. Step 2
becomes space-aware via an optional spaces input, so a Managed-only file
set is linted by managed:lint. New primary_attempts output records every
rung tried, which fills the gate ledger's not_run and ci_still_checks.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 5: Ledger wiring, reviewer contract, and the Phase 9 table

**Files:**
- Modify: `plugins/dev-workflows/commands/document.md` — Phase 5.8, Phase 6.4, Phase 6.5, Phase 7 dispatch, Phase 9 report, `## Invariants (always enforced)`
- Modify: `plugins/dev-workflows/agents/doc-reviewer.md` — `## Inputs`, `## Review dimensions`

**Interfaces:**
- Consumes: the `gate_ledger` block initialized in Task 3; `primary_attempts` from Task 4.
- Produces: a complete `gate_ledger` for every registry gate, passed to `doc-reviewer`; the Phase 9 `### Verification gates` table. Tasks 6, 8, and 9 append their own rows into the same block using this schema.

- [ ] **Step 1: Add the ledger-append instruction to Phase 6.4**

In `commands/document.md` Phase 6.4, replace the outcome list intro line `Act on the return:` with:

```markdown
Append the `style_check` ledger row before acting on the return (schema:
`${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §3), deriving its outcome from the agent's
`primary_attempts` and `complementary_linter`:

- a primary rung succeeded → `RAN`, `mechanism: <primary_linter>` (+ `dt-style-checker` when it ran).
- every primary rung failed but `dt-style-checker` ran → `DEGRADED`, `not_run:` one entry per failed
  rung from `primary_attempts`, and `ci_still_checks: "<the repo's own linter> runs on the PR in CI"`.
- `status: NOT_CONFIGURED` (no primary rung detected AND `dt-style-guide` absent) → `UNAVAILABLE`;
  convert it per `gate-ledger.md` §5 before proceeding.
- `status: ERROR` → `UNAVAILABLE`; convert it per `gate-ledger.md` §5.

Then act on the return:
```

Then replace the `status: NOT_CONFIGURED` bullet:

```markdown
- **`status: NOT_CONFIGURED`** — neither a repo linter NOR the `dt-style-checker` complementary pass was available (the agent already tried both). Proceed to Phase 7; `doc-reviewer` will still check correctness/completeness.
```

with:

```markdown
- **`status: NOT_CONFIGURED`** — no primary rung was detected AND `dt-style-guide` is not installed (the agent already climbed the whole ladder). This is a real coverage hole, not a no-op: the ledger row is `UNAVAILABLE` and `gate-ledger.md` §5 converts it before Phase 7. Never proceed on `NOT_CONFIGURED` without that conversion.
```

- [ ] **Step 2: Add the ledger-append instruction to Phase 5.8**

In `commands/document.md`, at the end of the Phase 5.8 section (immediately before the `---` that closes it), append:

```markdown
**Ledger.** Append the `source_truth_verification` row (schema:
`${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §3): `NOT_APPLICABLE` with
`precondition_unmet: "code_repos is empty"` when no repo resolved; `RAN` when verification ran against
the resolved repos; `DEGRADED` when any claim was resolved only by the supplementary grep, with
`not_run:` naming what did not (e.g. `diff-summarizer refresh: REFRESH_BLOCKED`). `findings:` is the
count of `verification_warnings` presented.
```

- [ ] **Step 3: Add the ledger-append instructions to Phase 6.5**

In `commands/document.md` Phase 6.5, at the very end of the section (immediately before the `---` that closes it, after the "Carry the table…" paragraph), append:

```markdown
**Ledger.** Append two rows (schema: `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §3):

- `build_check` — `NOT_APPLICABLE` with `precondition_unmet: "write context is <obsidian|plain_dir>"`
  when this phase was skipped entirely; `RAN` when a build command executed; `DEGRADED` when no build
  command exists and the Step 2 boot served as the proof, with
  `ci_still_checks: "the repo's build runs on the PR in CI"`; `FAILED` on a content failure;
  `UNAVAILABLE` when no build command exists **and** Step 2 did not run — convert it per
  `gate-ledger.md` §5.
- `render_smoke_check` — `RAN` when the smoke-check completed for every space in scope;
  `DEGRADED` when at least one space fell back to the manual table, with `not_run:` naming the space
  and its reason (prerequisite unmet / boot failure / readiness timeout);
  `SKIPPED_BY_USER` with the chosen option quoted verbatim when the user selected Skip;
  `NOT_APPLICABLE` with the precondition named when the phase did not apply.
```

- [ ] **Step 4: Add the `repo_checklist` placeholder row to Phase 6.4**

Immediately after the text added in Step 1 (before `Then act on the return:`), append:

```markdown
Also append the `repo_checklist` row: `NOT_APPLICABLE` with
`precondition_unmet: "the repo publishes no authoring or verification guidance"` when
`doc-planner`'s `repo_verification_gates` block is empty; otherwise `RAN` with `findings:` = the
number of checklist items that failed against the written files.
```

- [ ] **Step 5: Pass the ledger to `doc-reviewer`**

In `commands/document.md` Phase 7, replace these two dispatch lines:

```markdown
  > style-check report: [the violations output from Phase 6.4 — from docs-style-checker or dt-style-checker (fallback), or 'status: NOT_CONFIGURED' if neither ran]
  > render_verification: [the Phase 6.5 summary — build result; smoke-check per space (passed / skipped with reason); cross-space invariant check result]
```

with:

```markdown
  > style-check report: [the violations output from Phase 6.4 — from docs-style-checker or dt-style-checker; same violation schema regardless of source]
  > gate_ledger:        [the complete gate_ledger block — one row per gate in references/gate-ledger.md §4, including the Phase 0 toolchain_preflight row]
  > render_verification: [the Phase 6.5 summary — build result; smoke-check per space (passed / skipped with reason); cross-space invariant check result]
```

- [ ] **Step 6: Add the `gate_ledger` input to `doc-reviewer`**

In `agents/doc-reviewer.md` `## Inputs`, replace the Style-check report bullet:

```markdown
- **Style-check report** — the merged violations list from Phase 6.4 (`docs-style-checker` now chains the repo's primary linter + a complementary `dt-style-checker` semantic pass; each violation carries a `source: primary|complementary` tag), or `status: NOT_CONFIGURED` if no check could run. Same violation schema regardless of source.
```

with:

```markdown
- **Style-check report** — the merged violations list from Phase 6.4 (`docs-style-checker` chains the repo's primary linter ladder + a complementary `dt-style-checker` semantic pass; each violation carries a `source: primary|complementary` tag). Same violation schema regardless of source.
- **`gate_ledger`** — the run's completed gate ledger, one row per gate in `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §4, including the Phase 0 `toolchain_preflight` row. This is the evidence for the Verification-gate integrity dimension and replaces reading the style-check and render summaries narratively for that purpose.
```

- [ ] **Step 7: Add the Verification-gate integrity dimension**

In `agents/doc-reviewer.md`, in the `## Review dimensions` table, insert this row immediately before the `| Style-check follow-through |` row:

```markdown
| Verification-gate integrity | Check `gate_ledger` against `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` §4 and §6. **BLOCKER** when: a registry gate has no row; a row's outcome is `UNAVAILABLE` (§5 never converted it); `SKIPPED_BY_USER` carries an empty or absent `user_decision`; `NOT_APPLICABLE` carries an empty or absent `precondition_unmet`; or `DEGRADED` carries an empty `not_run` or `ci_still_checks`. A `DEGRADED` row that is fully populated is NOT a finding — note it and move on. Do NOT re-run any gate; the ledger is the evidence. Skip with "N/A — no gate ledger supplied" only when the input is absent entirely. |
```

- [ ] **Step 8: Rewrite the Style-check follow-through dimension**

Replace the existing `| Style-check follow-through |` row:

```markdown
| Style-check follow-through | Any unresolved style-check violations (from `docs-style-checker` or `dt-style-checker`) above MINOR are reflected as BLOCKER or MAJOR findings here. Do NOT re-lint — trust the style-checker's output. If the style-check report is `status: NOT_CONFIGURED`, skip this dimension ("N/A — no style checker ran"). |
```

with:

```markdown
| Style-check follow-through | Any unresolved style-check violations (from `docs-style-checker` or `dt-style-checker`) above MINOR are reflected as BLOCKER or MAJOR findings here. Do NOT re-lint — trust the style-checker's output. Skip this dimension only when the `style_check` ledger row is `NOT_APPLICABLE` or `SKIPPED_BY_USER` ("N/A — <the row's precondition_unmet or user_decision>"). A `DEGRADED` `style_check` row still carries violations from the fallback pass — review them normally; the coverage gap itself belongs to the Verification-gate integrity dimension, not here. |
```

- [ ] **Step 9: Add the Phase 9 `### Verification gates` section**

In `commands/document.md` Phase 9, insert this block immediately before the `### Render verification` heading:

```markdown
### Verification gates
| Gate | Outcome | Mechanism | Detail |
|---|---|---|---|
[One row per gate in the `gate_ledger`, in registry order (`references/gate-ledger.md` §4). "Detail" carries the row's `ci_still_checks` (DEGRADED), `user_decision` (SKIPPED_BY_USER), or `precondition_unmet` (NOT_APPLICABLE) — empty otherwise. When any row is DEGRADED, follow the table with a one-line warning naming what CI will check that this run did not.]
```

- [ ] **Step 10: Add the invariants**

In `commands/document.md`, in `## Invariants (always enforced)` (the Jira-mode list), insert these three bullets immediately after the `ALWAYS invoke \`docs-style-checker\` (Phase 6.4) before \`doc-reviewer\` (Phase 7)` bullet:

```markdown
- ALWAYS run the Phase 0 toolchain preflight (`${CLAUDE_PLUGIN_ROOT}/references/toolchain-preflight.md`) after profile resolution and before Phase 1; it prompts only when a required tool is missing
- ALWAYS append each gate's ledger row at the moment that gate completes, per `${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` — NEVER reconstruct the ledger at Phase 9, and NEVER leave a registry gate without a row
- NEVER present a phase's `choices:` array in an order, wording, or recommendation other than the one written; the "Choice lists are presented verbatim" rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` binds every prompt in this command
```

- [ ] **Step 11: Verify**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
echo "--- every registry gate has an append instruction (expect all 6 named) ---"
for g in toolchain_preflight source_truth_verification style_check repo_checklist build_check render_smoke_check; do
  printf "%-28s %s\n" "$g" "$(grep -c "$g" commands/document.md)"
done
echo "--- reviewer wiring ---"
grep -c "gate_ledger" agents/doc-reviewer.md
grep -c "Verification-gate integrity" agents/doc-reviewer.md
echo "--- Phase 9 table (expect 1 at ship c7bdac2 — see stale-at-ship note below) ---"
grep -n "^### Verification gates" commands/document.md
echo "--- NOT_CONFIGURED is no longer a proceed-silently path (expect 0) ---"
grep -c "NOT_CONFIGURED\*\* — neither a repo linter" commands/document.md
```
Expected: a non-zero count for all six gate ids; ≥ 2 for `gate_ledger` and ≥ 1 for `Verification-gate integrity` in the reviewer; one Phase 9 heading; and `0` for the old NOT_CONFIGURED wording.

**CORRECTED 2026-08-13 (R38, STALE-AT-SHIP):** "one Phase 9 heading" was correct as written — re-derived at this task's own ship commit `18ead6b` = 1, and still 1 at the sub-project's release commit `c7bdac2`. It was invalidated the next day by commit `0199f89` ("gate-ledger fix round — one-row-per-gate enforced at all four writers", 2026-08-10, F9: "add the missing Verification gates table to Mode B's report"), which gave direct mode (Mode B) its own `### Verification gates` heading. Current true count: **2** (one per mode, `document.md:1052` Jira mode and a second in Mode B's report template) — correct, not a defect; the check's fixed expectation of "one" is what went stale.

- [ ] **Step 12: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/document.md plugins/dev-workflows/agents/doc-reviewer.md
git commit -m "feat(dev-workflows): wire the gate ledger through /document

Each gate appends its row when it completes; doc-reviewer receives the
completed ledger and gains a Verification-gate integrity dimension that
BLOCKs on a missing row, an unconverted UNAVAILABLE, an unattributed
skip, or an underpopulated DEGRADED. Phase 9 prints the table.
NOT_CONFIGURED stops being a silent proceed — it is a coverage hole the
user must resolve.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 6: Render gate repair

**Files:**
- Modify: `plugins/dev-workflows/references/dynatrace-docs/render-verification.md`
- Modify: `plugins/dev-workflows/commands/document.md` — Phase 6.5 Step 1 and Step 2

**Interfaces:**
- Consumes: `commands.per_space.<space>.build` (Task 2); the verbatim-choice-list rule (Task 1); the `build_check` / `render_smoke_check` ledger rows (Task 5).
- Produces: nothing consumed downstream.

**Context:** `render-verification.md` §1 asserts the dynatrace-docs profile has no build command. That is false — `dynatrace:build` and `managed:build` exist — and the false claim is what disabled Phase 6.5's gating Step 1. Step 2 iterates `target_spaces` only, so the protected space's render, which the 3a invariant exists to defend, is never checked.

- [ ] **Step 1: Correct the build claim in `render-verification.md`**

Replace §1 in full:

```markdown
## 1. Build vs boot

Run `profile.commands.build` only if the profile defines one. Phase 6.5 does NOT
re-run the prose linter — that is Phase 6.4's `docs-style-checker`. When the
profile defines no build command (the dynatrace-docs case: only
`commands.lint` + the `*:start` dev servers), the **dev-server boot is the build
proof** — a server that boots and serves HTTP 200s proves the content compiled.
```

with:

```markdown
## 1. Build vs boot

Resolve the build command per space: `profile.commands.per_space.<space>.build` when the profile
declares one for that space, else the flat `profile.commands.build`. Run it for each space written to.
For dynatrace-docs that is `pnpm dynatrace:build` and `pnpm managed:build` — both exist, and an
earlier version of this file wrongly claimed the repo had only `commands.lint` and the `*:start`
servers, which disabled this gate entirely.

Phase 6.5 does NOT re-run the prose linter — that is Phase 6.4's `docs-style-checker`.

Only when a repo genuinely declares **no** build command at either level does the **dev-server boot
become the build proof** — a server that boots and serves HTTP 200s proves the content compiled. That
is a fallback for repos without a build, not a description of dynatrace-docs.
```

- [ ] **Step 2: Make §2 boot both spaces**

Replace §2's opening two sentences:

```markdown
`profile.dev_servers.concurrent: false` means one space at a time. For each space
in `target_spaces`, in order:
```

with:

```markdown
`profile.dev_servers.concurrent: false` means one space at a time.

**Which spaces to boot.** Start from `target_spaces`. When any affected page's `write_strategy.strategy`
is `conditional` or `override-copy`, **add that strategy's protected space** — the space that is *not*
its `target_space`. The invariant in §4 has two halves (marker PRESENT in the target render, ABSENT in
the protected render) and booting only `target_spaces` can never check the second one, which is the
half the 3a protection depends on. On a run with no cross-space pages, the set is just `target_spaces`.

For each space in that set, in order:
```

- [ ] **Step 3: Declare static analysis insufficient**

At the end of `render-verification.md` §6, append:

```markdown
**Static analysis is necessary but never sufficient.** A correct `{{#if project='…'}}` wrapping, a
clean link-integrity grep, and a verified conditional structure all corroborate the render gate and
none of them satisfy it. Static greps do not catch Handlebars compile errors, do not prove
`managed/docstack.jsonc`'s allowlist actually pulls a shared page into the managed render, and do not
prove a postid resolves in the managed build. A run that has only static evidence has not run this
gate — record `render_smoke_check` accordingly.
```

- [ ] **Step 4: Fix Phase 6.5 Step 1 in the command**

In `commands/document.md`, replace Step 1's opening line:

```markdown
Run `profile.commands.build` if the profile defines one. Do NOT re-run the Phase 6.4 prose linter. Classify any failure:
```

with:

```markdown
Resolve the build command per space — `profile.commands.per_space.<space>.build`, else the flat `profile.commands.build` — and run it for each space written to. Do NOT re-run the Phase 6.4 prose linter. Classify any failure:
```

Then replace:

```markdown
When the profile defines **no** build command (the dynatrace-docs case), record "no build command in profile; build proof deferred to the dev-server boot (Step 2)" and proceed.
```

with:

```markdown
When the profile declares **no** build command at either level, record "no build command in profile; build proof deferred to the dev-server boot (Step 2)" and proceed. Under the built-in dynatrace-docs profile this branch does not apply — `commands.per_space.saas.build` and `commands.per_space.managed.build` are both defined.
```

- [ ] **Step 5: Bind Step 2's choice list and both-space boot**

In `commands/document.md` Phase 6.5 Step 2, replace:

```markdown
Offer it:
```
```
choices: ["Run smoke-check (Recommended)", "Skip — use the manual table only", "Cancel"]
```
```

with:

```markdown
Offer it. Present this list **verbatim** — the "Choice lists are presented verbatim" rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` forbids moving `(Recommended)`, reordering the options, or re-wording them. Dev-server flakiness and a correct static conditional are reasons to say something in prose beside the list; they are never reasons to recommend Skip.
```
```
choices: ["Run smoke-check (Recommended)", "Skip — use the manual table only", "Cancel", "Other… (describe)"]
```
```

Then replace the loop's opening:

```markdown
When run, for each space in `target_spaces`, **sequentially** (`profile.dev_servers.concurrent: false` forbids overlap) — full mechanics in `render-verification.md`:
```

with:

```markdown
When run, boot each space in the **verification set** — `target_spaces` plus, when any affected page's `write_strategy.strategy` is `conditional` or `override-copy`, that strategy's protected space (see `render-verification.md` §2) — **sequentially** (`profile.dev_servers.concurrent: false` forbids overlap). Booting only `target_spaces` can never check the ABSENT half of the §4 invariant. Full mechanics in `render-verification.md`:
```

- [ ] **Step 6: Verify**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
echo "--- false 'no build command' claim gone (expect 0) ---"
grep -c "the dynatrace-docs case: only" references/dynatrace-docs/render-verification.md
echo "--- protected space is booted (expect >=1 each) ---"
grep -c "protected space" references/dynatrace-docs/render-verification.md
grep -c "verification set" commands/document.md
echo "--- static insufficiency stated (expect >=1) ---"
grep -c "necessary but never sufficient" references/dynatrace-docs/render-verification.md
echo "--- choice list bound (expect >=1) ---"
grep -c "forbids moving \`(Recommended)\`" commands/document.md
```
Expected: `0`, then non-zero counts for each remaining check.

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/dynatrace-docs/render-verification.md plugins/dev-workflows/commands/document.md
git commit -m "fix(dev-workflows): repair /document's render gate

The reference claimed dynatrace-docs has no build command, which disabled
Phase 6.5's gating Step 1; dynatrace:build and managed:build both exist.
Step 2 now boots the protected space as well as the target, so the ABSENT
half of the cross-space invariant is actually checked, and its choice list
is bound by the verbatim rule so (Recommended) cannot move onto Skip.
Static conditional analysis is declared necessary but never sufficient.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 7: `changelog-guidelines.md` wiring

**Files:**
- Modify: `plugins/dev-workflows/agents/doc-planner.md`
- Modify: `plugins/dev-workflows/agents/doc-writer.md`
- Modify: `plugins/dev-workflows/agents/doc-reviewer.md`

**Interfaces:**
- Consumes: `profile.frontmatter.changelog_guidelines` (already present in the profile).
- Produces: nothing consumed downstream.

**Context:** `references/dynatrace-docs/changelog-guidelines.md` currently has **zero consumers in the write path**. `doc-planner`, `doc-writer`, and `doc-reviewer` each carry two inlined rules ("customer-readable 1-line summary", "no Jira key"). The full guideline lives only in the `dynatrace-docs-frontmatter` skill, which no agent invokes and `doc-writer` cannot invoke — its tool list has no Skill. Agents *can* read files, so the fix is a read, not a duplication.

- [ ] **Step 1: `doc-planner` reads the guideline**

In `agents/doc-planner.md`, replace the `changelog:` planning bullet:

```markdown
   - `changelog:` — append a dated entry with a customer-readable 1-line change summary and NO Jira key. Create the field if it doesn't exist on an extended page. This is mandatory on every target. The Jira reference is carried by the commit message and the file diff, not by the reader-visible page (verified against the repo convention — fewer than 5 of dynatrace-docs's 5500+ entries cite an issue key).
```

with:

```markdown
   - `changelog:` — append a dated entry with a customer-readable 1-line change summary and NO Jira key. Create the field if it doesn't exist on an extended page. This is mandatory on every target. The Jira reference is carried by the commit message and the file diff, not by the reader-visible page (verified against the repo convention — fewer than 5 of dynatrace-docs's 5500+ entries cite an issue key).
     **Read the guideline before drafting the entry.** When `profile.frontmatter.changelog_guidelines` resolves to a file, read it (for dynatrace-docs: `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/changelog-guidelines.md`) and draft each entry to conform. It is the source of truth for customer point of view, the "to what effect?" test, verb variety, and the period rule. Do NOT restate its rules in the checklist — plan an entry that already satisfies them. When the pointer is absent, the two rules above are the whole requirement.
```

- [ ] **Step 2: `doc-writer` applies the guideline**

In `agents/doc-writer.md`, replace frontmatter step 2:

```markdown
2. **Add or update** the `changelog:` field per the planner's checklist (append a dated entry with a customer-readable 1-line change summary and **no Jira key** — traceability lives in the commit message, not the reader-visible page). Create the field if it doesn't exist on an extended page.
```

with:

```markdown
2. **Add or update** the `changelog:` field per the planner's checklist (append a dated entry with a customer-readable 1-line change summary and **no Jira key** — traceability lives in the commit message, not the reader-visible page). Create the field if it doesn't exist on an extended page. When `profile.frontmatter.changelog_guidelines` resolves to a file, read it (for dynatrace-docs: `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/changelog-guidelines.md`) and make the written entry conform — customer point of view, the "to what effect?" test, varied verbs, and the period rule. Never write internal render-mechanic terms such as "Managed-only" into a changelog entry; the reader does not know what a space is.
```

- [ ] **Step 3: `doc-reviewer` checks conformance**

In `agents/doc-reviewer.md`, in the `| YAML frontmatter |` dimension row, replace the opening sentence:

```markdown
`changelog:` is updated with a customer-readable 1-line summary (and **no** Jira key) per the `doc-planner` checklist.
```

with:

```markdown
`changelog:` is updated with a customer-readable 1-line summary (and **no** Jira key) per the `doc-planner` checklist, and — when `profile.frontmatter.changelog_guidelines` resolves to a file (for dynatrace-docs: `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/changelog-guidelines.md`) — **conforms to that guideline**: customer point of view, passes the "to what effect?" test (no meta phrasing such as "a note linking X to this section"), varied verbs rather than a run of "Added", the period rule, and no internal render-mechanic jargon such as "Managed-only". A non-conforming entry is **MAJOR**. Read the guideline before judging; do not rely on the two summary rules alone.
```

- [ ] **Step 4: Verify the guideline now has consumers**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
echo "--- write-path consumers (expect 3) ---"
grep -l "changelog-guidelines.md" agents/doc-planner.md agents/doc-writer.md agents/doc-reviewer.md | wc -l
echo "--- the jargon ban is stated (expect >=2) ---"
grep -c "Managed-only" agents/doc-writer.md agents/doc-reviewer.md | paste -sd' '
```
Expected: `3`, and a non-zero count for both files.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/doc-planner.md plugins/dev-workflows/agents/doc-writer.md plugins/dev-workflows/agents/doc-reviewer.md
git commit -m "fix(dev-workflows): give changelog-guidelines.md consumers in the write path

The guideline was cited only by a skill no agent can invoke, so doc-planner,
doc-writer and doc-reviewer each worked from two inlined rules. All three now
read the reference itself when the profile's pointer resolves; a non-conforming
entry is a MAJOR reviewer finding. No rule text is duplicated.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 8: `repo_verification_gates`

**Files:**
- Modify: `plugins/dev-workflows/agents/doc-planner.md` — the guidance-scan paragraph, the output schema, the hard rules
- Modify: `plugins/dev-workflows/agents/doc-reviewer.md` — `## Inputs`, a new dimension row

**Interfaces:**
- Consumes: nothing from earlier tasks except the `repo_checklist` ledger row wired in Task 5.
- Produces: `doc-planner`'s new `repo_verification_gates:` output block, consumed by `doc-reviewer` and by the Phase 6.4 `repo_checklist` ledger row.

**Context:** `doc-planner` is instructed to *"**Ignore** purely operational content (build/setup steps, PR and branch mechanics)."* `dynatrace-docs`' `CONTRIBUTING.md` puts its entire pre-PR quality gate under `## PR checklist → Advanced check (InfoDevs)` — frontmatter fields, changelog conformance, sensitive information, duplicate headers, terminology, walls of text, "Validate the change. The validation must pass with no errors or warnings." That is operational content, so the one section listing the gates that failed is the section the planner throws away.

- [ ] **Step 1: Extend the guidance scan**

In `agents/doc-planner.md`, replace the final two sentences of the "First — read the repo's own authoring guidance" paragraph:

```markdown
These rules **augment, never override** the built-in dynatrace-docs references and the `dt-style-guide` checks; when a repo rule conflicts with those, note it rather than silently overriding. Factor the extracted rules into the topic and section planning below. Emit `repo_authoring_guidance: []` when no guidance files exist or none carry authoring rules.
```

with:

```markdown
These rules **augment, never override** the built-in dynatrace-docs references and the `dt-style-guide` checks; when a repo rule conflicts with those, note it rather than silently overriding. Factor the extracted rules into the topic and section planning below. Emit `repo_authoring_guidance: []` when no guidance files exist or none carry authoring rules.

**Second — extract the repo's pre-PR verification gates from the same files.** The instruction above ignores operational content for *planning* purposes, but a repo's own pre-merge checklist is not noise: it is the list of checks a human reviewer will apply. Follow `${CLAUDE_PLUGIN_ROOT}/references/repo-verification-gates.md` §2–§4 — it owns the heading patterns to look for, what counts as checkable, what to exclude, and the block's schema — and emit the resulting `repo_verification_gates` block. Do NOT restate its rules here; the reference is the single source of truth, and `/document` direct mode follows the same procedure without a planner.

For `dynatrace-docs` this resolves to `CONTRIBUTING.md` `## PR checklist` (both the Contributors minimum check and the InfoDevs advanced check).
```

- [ ] **Step 2: Add the output block**

In `agents/doc-planner.md`, in the `## Output — the documentation checklist` YAML, insert immediately after the `repo_authoring_guidance:` block and before `checklist:`:

```yaml
repo_verification_gates:        # the repo's own pre-PR checks that are checkable against the written files; [] when none
  - check:  <one checkable requirement, phrased as a testable assertion>
    source: <file + section, e.g. "CONTRIBUTING.md § PR checklist → Advanced check (InfoDevs)">
    kind:   frontmatter | content | structure | terminology | validation
```

- [ ] **Step 3: Add the hard rules**

In `agents/doc-planner.md`'s `## Hard rules`, insert after the `NEVER include a Jira key inside frontmatter_updates.changelog.entry` bullet:

```markdown
- The `repo_verification_gates` block obeys `${CLAUDE_PLUGIN_ROOT}/references/repo-verification-gates.md` §6 in full — never emit an entry that cannot be checked against the files this run writes, never paraphrase a repo gate into a different requirement, and never let a repo gate silently override a built-in reference.
```

- [ ] **Step 4: Give the reviewer the block**

In `agents/doc-reviewer.md` `## Inputs`, replace the `doc-planner` checklist bullet:

```markdown
- **`doc-planner` checklist** — the full YAML checklist from Phase 5.7 (review against plan), including the planner's `repo_authoring_guidance` block (the repo-specific authoring rules to check adherence against).
```

with:

```markdown
- **`doc-planner` checklist** — the full YAML checklist from Phase 5.7 (review against plan), including the planner's `repo_authoring_guidance` block (the repo-specific authoring rules to check adherence against) and its `repo_verification_gates` block (the repo's own pre-PR checks).
```

- [ ] **Step 5: Add the reviewer dimension**

In `agents/doc-reviewer.md`'s `## Review dimensions` table, insert this row immediately after the `| Repo authoring guidance |` row:

```markdown
| Repo verification gates | Every entry in the planner's `repo_verification_gates` holds against the written files. A failing gate is **MAJOR** (BLOCKER when the repo's own wording marks it mandatory — e.g. "The validation must pass with no errors or warnings"). Cite the gate's `source` file and section in the finding so the author can look it up. A `validation`-kind gate that the run could not execute is not a finding here — that belongs to the Verification-gate integrity dimension via the `build_check` / `style_check` ledger rows. Skip with "N/A — the repo publishes no pre-PR checklist" when the block is empty. |
```

- [ ] **Step 6: Verify**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
echo "--- planner emits it (expect 3) ---"
grep -c "repo_verification_gates" agents/doc-planner.md
# CORRECTED 2026-08-13 (R38): original expected >=4; re-derived at ship commit 1b941f5 = 3 (WRONG, was already wrong at ship — doc-planner.md never carried a 4th occurrence). Old: ">=4". New: "3".
echo "--- reviewer consumes it (expect >=2) ---"
grep -c "repo_verification_gates" agents/doc-reviewer.md
echo "--- the dynatrace-docs anchor is named (expect >=1) ---"
grep -c "PR checklist" agents/doc-planner.md
echo "--- the real section still exists in the repo ---"
grep -n "^### Advanced check (InfoDevs)" /workspace/docs/CONTRIBUTING.md
```
Expected: counts as annotated, and one match in the real `CONTRIBUTING.md` — confirming the anchor the planner is told to look for is genuinely there.

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/doc-planner.md plugins/dev-workflows/agents/doc-reviewer.md
git commit -m "feat(dev-workflows): ingest the docs repo's own pre-PR checklist

doc-planner's 'ignore operational content' rule discarded the one section
listing the checks a human reviewer applies. It now additionally emits
repo_verification_gates from the same guidance files, and doc-reviewer
gains a dimension that holds the written files against them and cites the
repo's own section in each finding.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 9: Commands/CLI claim class and the supplementary grep

**Files:**
- Modify: `plugins/dev-workflows/references/source-truth.md` — the §2 claim-class table, a new §3 technique
- Modify: `plugins/dev-workflows/agents/doc-reviewer.md` — the Source-code accuracy dimension
- Modify: `plugins/dev-workflows/commands/document.md` — Phase 5.8

**Interfaces:**
- Consumes: the `source_truth_verification` ledger row wired in Task 5.
- Produces: nothing consumed downstream.

**Context:** the §2 table covers enums, UI labels, menu paths, defaults, feature flags, API paths, nullability, concurrency, permissions, and counts. There is no row for commands or code blocks — so the wrong `helm` command on PRODUCT-17012 was never in scope for verification. Separately, Phase 5.8 escalates `AMBIGUOUS` / `NOT_FOUND` warnings to the user even when the repo is resolved in `code_repos`; the user resolved one by grepping the clone by hand.

- [ ] **Step 1: Add the claim-class row**

In `references/source-truth.md` §2, append this row to the claim-type table, immediately after the `**Headline counts**` row:

```markdown
| **Commands, CLI invocations, and copy-paste code blocks** (helm/kubectl/pnpm invocations, flags, image references, chart names, registry paths, YAML keys inside fenced blocks) | Chart and manifest files in the source repo (`Chart.yaml`, `values.yaml`, `templates/**`), the CI/release workflow that publishes the artifact, sibling docs pages that already carry the same command, and `--help` / usage strings in the CLI source |
```

- [ ] **Step 2: Add the verification technique**

In `references/source-truth.md` §3, append a new subsection after the last existing technique:

```markdown
### 3.7 Commands and fenced code blocks

A reader runs a documented command verbatim, so a wrong flag or a wrong registry path is a
customer-facing defect with no recovery. Verify every command the docs introduce or change:

```bash
# the artifact's own definition
find <repo_path> \( -name Chart.yaml -o -name values.yaml \) 2>/dev/null

# the published name/path, as the release pipeline writes it
grep -rn "<chart-or-image-name>" <repo_path>/.github/workflows <repo_path>/.ci 2>/dev/null

# what the docs already say elsewhere — sibling pages are strong corroboration
grep -rn "<command-head>" <docs_repo_path> --include="*.md" 2>/dev/null
```

A command that no source confirms is `NOT_FOUND`, not "probably fine". Record it as a
`verification_warning` like any other claim and let the caller escalate it.
```

- [ ] **Step 3: Grade unverified commands MAJOR in the reviewer**

In `agents/doc-reviewer.md`, in the `| Source-code accuracy |` dimension row, replace the final sentence:

```markdown
A claim that cannot be verified (no/partial `code_repos`) is a MAJOR with a "not verifiable" note — never a BLOCKER.
```

with:

```markdown
A claim that cannot be verified (no/partial `code_repos`) is a MAJOR with a "not verifiable" note — never a BLOCKER. **Commands and fenced code blocks are checked in every run**, whether or not other claims were spot-checked: readers run them verbatim, so an unverified command is a MAJOR even when the rest of the page verified cleanly, and one contradicted by source is a BLOCKER like any other wrong claim.
```

- [ ] **Step 4: Add the supplementary grep to Phase 5.8**

In `commands/document.md` Phase 5.8, insert immediately before the step that presents the discrepancy table to the user:

```markdown
**Supplementary resolution (one attempt, before presenting anything).** For every
`verification_warning` whose `finding` is `AMBIGUOUS` or `NOT_FOUND`, check whether the relevant repo
is present in the Phase-4 `code_repos` map. When it is, run **one** direct grep against that resolved
local path to try to resolve the claim — using the `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md`
§3 technique matching the claim's type — **including when `diff-summarizer` returned `REFRESH_BLOCKED`
for that repo**. A read-only mount that cannot `git fetch` can still be grepped, and this is exactly
the case a user previously had to resolve by hand.

Update the warning in place when the grep resolves it (`finding: VERIFIED` or `CONTRADICTED`, with
`source_phrasing` and `source_location` filled from the grep). Present only what remains unresolved.
Record the outcome in the `source_truth_verification` ledger row: a resolution obtained this way makes
the row `DEGRADED`, with `not_run:` naming what did not run (e.g.
`diff-summarizer refresh: REFRESH_BLOCKED`), never a clean `RAN`.
```

- [ ] **Step 5: Verify**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
echo "--- claim class present (expect >=1) ---"
grep -c "Commands, CLI invocations, and copy-paste code blocks" references/source-truth.md
echo "--- technique added (expect 1) ---"
grep -c "^### 3.7 Commands and fenced code blocks" references/source-truth.md
echo "--- reviewer grades commands (expect >=1) ---"
grep -c "readers run them verbatim" agents/doc-reviewer.md
echo "--- supplementary grep wired, REFRESH_BLOCKED included (expect >=1) ---"
grep -c "Supplementary resolution" commands/document.md
```
Expected: non-zero for each.

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/source-truth.md plugins/dev-workflows/agents/doc-reviewer.md plugins/dev-workflows/commands/document.md
git commit -m "feat(dev-workflows): verify commands and code blocks against source

source-truth.md gains a claim class for commands, CLI invocations and
fenced code blocks, plus a technique for checking them against charts,
release workflows and sibling pages — the class the wrong helm command
fell outside of. doc-reviewer checks them in every run at MAJOR. Phase 5.8
now runs one supplementary grep against a resolved local repo before
escalating AMBIGUOUS/NOT_FOUND, including under REFRESH_BLOCKED.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 10: Canonical docs, version, and catalog

**Files:**
- Modify: `plugins/dev-workflows/README.md`
- Modify: `plugins/dev-workflows/CHANGELOG.md`
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `CLAUDE.md` (repo root)

**Interfaces:**
- Consumes: everything from Tasks 1–9.
- Produces: version 2.43.0 in both canonical locations; the reference index entries Tasks 11 and 12 mirror.

- [ ] **Step 1: Index the two new references in the README**

In `plugins/dev-workflows/README.md`, in the reference-list section (the one containing the `references/branch-naming.md` bullet), insert two bullets immediately after the `references/branch-naming.md` entry:

```markdown
- `references/toolchain-preflight.md` — the Phase 0 environment check: derives the run's required tool set from the resolved profile (`commands.*`, `commands.per_space.*`, `dev_servers`, `prerequisites`), the repo's config signals (`.vale.ini`, lockfiles, `node_modules/`, `.markdownlint.json`, `.remarkrc*`), and the repo's own documented `Prerequisites` section; maps each tool to the gates it powers so the run can state its outcome before it happens; prompts only when something is missing, recommending Cancel so a run started in the wrong container stops before writing. Consumed by `/document` (both modes)
- `references/gate-ledger.md` — the six-outcome vocabulary (`RAN` / `DEGRADED` / `FAILED` / `UNAVAILABLE` / `SKIPPED_BY_USER` / `NOT_APPLICABLE`) with **no orchestrator-assignable skip**: every non-run path ends in a named missing precondition, a named missing tool, or the user's verbatim decision. Carries the `/document` gate registry, the `UNAVAILABLE` conversion prompt, and the reviewer contract that makes a missing or unattributed row a BLOCKER. Consumed by `/document` (both modes); written generically for other commands to adopt
- `references/repo-verification-gates.md` — finding and extracting a docs repo's **own** pre-PR checklist (`CONTRIBUTING.md` `## PR checklist` and its equivalents) and turning it into the `repo_verification_gates` block: which headings to look for, which items are checkable against the written files, and the rule that a repo gate augments but never overrides a built-in reference. Applied by `doc-planner` in Jira mode and by the orchestrator itself in direct mode, which has no planner
```

- [ ] **Step 2: Update the `/document` command row in the README**

Find the `/document` row of the commands table and append to its description cell:

```
Phase 0 runs a toolchain preflight (stops a run whose linter/build tooling is absent), and every verification gate records a ledger row that `doc-reviewer` gates on.
```

- [ ] **Step 3: Add the CHANGELOG entry**

At the top of `plugins/dev-workflows/CHANGELOG.md`, immediately after the file's header and before the `## [2.42.0]` heading, insert:

```markdown
## [2.43.0] — 2026-08-08

### Added

- **`/document` Phase 0 toolchain preflight — new `references/toolchain-preflight.md`.** Before anything is written, the run derives the tools its gates will invoke — from the resolved profile (`commands.*`, `commands.per_space.*`, `dev_servers[].command`, `prerequisites`), the repo's config signals (`.vale.ini`, `pnpm-lock.yaml`/`package-lock.json`/`yarn.lock`, `node_modules/`, `.markdownlint.json(c)`, `.remarkrc*`), and the repo's own documented `Prerequisites` section — checks each with `command -v` / `test -d`, and maps every tool to the gates it powers. On a healthy container it contributes one Readiness row and never prompts. When something is missing it states the run's outcome in advance ("with `vale` and `pnpm` missing, `style_check` would be DEGRADED, `build_check` and `render_smoke_check` UNAVAILABLE") and offers Cancel as the recommended option, so a run started in the wrong container stops before writing rather than shipping quieter, worse documentation behind a green CI. Direct mode gets the same check scoped to the style gate, deriving its required set without a profile.
- **Gate ledger — new `references/gate-ledger.md`.** Six outcomes — `RAN`, `DEGRADED`, `FAILED`, `UNAVAILABLE`, `SKIPPED_BY_USER`, `NOT_APPLICABLE` — and **none of them is an orchestrator-assignable "skipped"**. Every non-run path terminates in a named missing precondition, a named missing tool, or the user's decision quoted verbatim; `UNAVAILABLE` is explicitly not a resting state and is converted by asking. Each gate appends its row **when it completes**, never reconstructed at report time. `doc-reviewer` gains a **Verification-gate integrity** dimension that BLOCKs on a missing row, an unconverted `UNAVAILABLE`, an unattributed skip, or an underpopulated `DEGRADED`, and Phase 9 prints a `### Verification gates` table naming what CI will check that the run did not.
- **"Choice lists are presented verbatim" in `references/escalation-rules.md`** — a phase's options, their order, their wording, and the `(Recommended)` marker are not the orchestrator's to change; an orchestrator that disagrees says so in prose beside the list. Binds every command. This is the rule a `/document` run broke when it moved `(Recommended)` onto Phase 6.5's Skip option and never exercised the render gate.
- **`commands.per_space` in the docs profile.** `dynatrace-docs` defines `dynatrace:lint`, `managed:lint`, `dynatrace:build`, and `managed:build`; the built-in profile knew only `pnpm dynatrace:lint` and no build command at all. Per-space `lint`/`build`/`format` are now declared, documented in `docs-profile-schema.md`, and detected by `/docs-profile`.
- **Commands and code blocks are a verified claim class.** `references/source-truth.md` §2 gains a row for helm/kubectl/pnpm invocations, flags, image references, chart names, registry paths, and YAML keys in fenced blocks, plus a §3.7 technique that checks them against `Chart.yaml`/`values.yaml`/`templates/**`, the release workflow, sibling docs pages, and `--help` output. `doc-reviewer` checks them in **every** run at MAJOR — readers run a documented command verbatim, so an unverified one is a defect even when the rest of the page verified cleanly.
- **`repo_verification_gates` from `doc-planner`.** The repo's own pre-PR checklist — for `dynatrace-docs`, `CONTRIBUTING.md` `## PR checklist` — is now extracted and checked, instead of being discarded by the planner's "ignore operational content" rule. `doc-reviewer` holds the written files against each gate and cites the repo's own section in the finding.

### Fixed

- **`docs-style-checker` climbs the ladder instead of jumping off it.** A failure at any primary rung now continues to the next rung; previously every step-1/2/3 failure jumped straight to `dt-style-checker`, so a repo with a `.vale.ini` but no `vale` binary silently abandoned `pnpm dynatrace:lint` — the linter CI actually runs. Step 2 also becomes space-aware through a new optional `spaces` input, so a Managed-only file set is linted by `managed:lint` rather than the SaaS linter, and a new `primary_attempts` output records every rung tried, which is what fills the ledger's `not_run` and `ci_still_checks`.
- **`references/dynatrace-docs/render-verification.md` no longer claims dynatrace-docs has no build command.** That false statement disabled Phase 6.5's gating Step 1 outright; `dynatrace:build` and `managed:build` both exist and now run per space.
- **The render smoke-check boots the protected space, not only the target.** The cross-space invariant has two halves — the delta marker PRESENT in the target render and ABSENT in the protected one — and iterating `target_spaces` alone could never check the second, which is the half the 3a protection depends on. Static conditional analysis is declared necessary but never sufficient: it corroborates the gate and can never satisfy it.
- **`changelog-guidelines.md` has consumers in the write path.** It was cited only by a skill that no agent invokes and `doc-writer` cannot invoke (its tool list has no Skill), so `doc-planner`, `doc-writer`, and `doc-reviewer` each worked from two inlined rules. All three now read the reference itself; a non-conforming entry — meta phrasing, a run of "Added", internal jargon such as "Managed-only", a broken period rule — is a MAJOR reviewer finding. No rule text is duplicated.
- **Phase 5.8 tries once more before escalating.** An `AMBIGUOUS`/`NOT_FOUND` verification warning whose repo is resolved in `code_repos` now gets one supplementary direct grep against the local path — **including when `diff-summarizer` returned `REFRESH_BLOCKED`**, since a read-only mount that cannot `git fetch` can still be grepped. Resolving a claim this way records the gate as `DEGRADED`, never a clean `RAN`.
- **`status: NOT_CONFIGURED` stops being a silent proceed.** It now maps to an `UNAVAILABLE` ledger row that must be converted by asking the user, rather than a no-op on the way to the reviewer.
```

- [ ] **Step 4: Bump both canonical version locations**

```bash
cd /workspace/ihudak-claude-plugins
python3 - <<'PY'
import json, re
p = "plugins/dev-workflows/.claude-plugin/plugin.json"
s = open(p).read()
s2 = s.replace('"version": "2.42.0"', '"version": "2.43.0"', 1)
assert s != s2, "plugin.json version not found"
open(p, "w").write(s2)

p = ".claude-plugin/marketplace.json"
d = json.load(open(p))
plugins = d["plugins"] if isinstance(d, dict) and "plugins" in d else d
hit = [x for x in plugins if x.get("name") == "dev-workflows"]
assert len(hit) == 1, f"expected exactly one dev-workflows entry, got {len(hit)}"
assert hit[0]["version"] == "2.42.0", hit[0]["version"]
print("catalog entry before:", hit[0]["version"], "| siblings:", [x.get("name") for x in plugins])
PY
```

Then edit `.claude-plugin/marketplace.json` **by hand** (do not rewrite the file programmatically — it must not be reformatted): change only the `dev-workflows` entry's `"version"` to `"2.43.0"`, and extend that same entry's `"description"` with:

```
Phase 0 toolchain preflight + gate ledger: every verification gate records an outcome the orchestrator cannot fake, and a run started without the required tooling stops before writing.
```

Leave the other three plugin entries untouched.

- [ ] **Step 5: Update the root `CLAUDE.md`**

In `/workspace/ihudak-claude-plugins/CLAUDE.md`, under `## Source-truth reference`, append two paragraphs:

```markdown
`plugins/dev-workflows/references/gate-ledger.md` is the **single source of truth** for verification-gate accounting — the six outcomes (`RAN` / `DEGRADED` / `FAILED` / `UNAVAILABLE` / `SKIPPED_BY_USER` / `NOT_APPLICABLE`), the rule that **no outcome is orchestrator-assignable to mean "I decided not to run this"**, the `/document` gate registry, the `UNAVAILABLE` conversion prompt, and the reviewer contract. Consumed by `/document` (both modes) and written generically for other commands to adopt.

`plugins/dev-workflows/references/repo-verification-gates.md` is the **single source of truth** for extracting a docs repo's own pre-PR checklist into the `repo_verification_gates` block — the heading patterns, what counts as checkable against the written files, and the augment-never-override rule. Applied by `doc-planner` in `/document` Jira mode and by the orchestrator itself in direct mode, which has no planner.

`plugins/dev-workflows/references/toolchain-preflight.md` is the **single source of truth** for the Phase 0 environment check — deriving the required tool set from the resolved profile, the repo's config signals, and the repo's own documented `Prerequisites`; the `toolchain` block with its tool→gate map; and the missing-tool prompt (Cancel recommended, silence when everything resolves). Consumed by `/document` (both modes).
```

Then, in the `## Key invariants` section for `/document` (Jira mode), append three bullets:

```markdown
- Phase 0 runs the toolchain preflight after profile resolution; it prompts **only** when a required tool is missing, and Cancel is the recommended option
- Every gate in the `gate-ledger.md` registry appends its row **when the gate completes**; a missing row, an unconverted `UNAVAILABLE`, or an unattributed skip is a `doc-reviewer` BLOCKER
- A phase's `choices:` array is presented verbatim — order, wording, and the `(Recommended)` marker are not the orchestrator's to change
```

- [ ] **Step 6: Verify the canonical repo end to end**

Run:
```bash
cd /workspace/ihudak-claude-plugins
echo "--- versions (expect 2.43.0 twice) ---"
python3 -c "
import json
print(json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'))['version'])
d=json.load(open('.claude-plugin/marketplace.json')); ps=d.get('plugins',d)
print([p['version'] for p in ps if p['name']=='dev-workflows'][0])
print('siblings untouched:', [(p['name'],p['version']) for p in ps if p['name']!='dev-workflows'])
"
echo "--- all JSON still valid ---"
python3 -c "import json;[json.load(open(f)) for f in ['.claude-plugin/marketplace.json','plugins/dev-workflows/.claude-plugin/plugin.json']];print('json ok')"
echo "--- new references indexed (expect 1 each) ---"
grep -c "references/gate-ledger.md" plugins/dev-workflows/README.md
grep -c "references/toolchain-preflight.md" plugins/dev-workflows/README.md
grep -c "gate-ledger.md" CLAUDE.md
echo "--- changelog entry (expect 1) ---"
grep -c "^## \[2.43.0\]" plugins/dev-workflows/CHANGELOG.md
echo "--- spec verification list, items 5-9 ---"
cd plugins/dev-workflows
grep -l "changelog-guidelines.md" agents/doc-planner.md agents/doc-writer.md agents/doc-reviewer.md | wc -l   # expect 3
grep -c "go to step 5" agents/docs-style-checker.md                                                          # expect 0
grep -c "the dynatrace-docs case: only" references/dynatrace-docs/render-verification.md                     # expect 0
grep -c "Commands, CLI invocations" references/source-truth.md                                               # expect >=1
grep -c "Choice lists are presented verbatim" references/escalation-rules.md commands/document.md | paste -sd' '
```
Expected: `2.43.0` twice; the three sibling plugins unchanged; `json ok`; `1` for each index check; `1` changelog entry; then `3`, `0`, `0`, `≥1`, and non-zero counts for the verbatim rule in both files.

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/README.md plugins/dev-workflows/CHANGELOG.md plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json CLAUDE.md
git commit -m "docs(dev-workflows): 2.43.0 — gate enforcement docs, version, catalog

Indexes gate-ledger.md and toolchain-preflight.md in the README and the
repo CLAUDE.md, records the release in the CHANGELOG, and bumps both
canonical version locations (plugin.json + marketplace.json) — the catalog
was missed in 2.42.0 and is explicit here.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 11: Port to mgd-claude-plugins

**Files (in `/workspace/mgd-claude-plugins`):**
- Copy verbatim from canonical: `plugins/dev-workflows/references/gate-ledger.md` (new), `references/toolchain-preflight.md` (new), `references/repo-verification-gates.md` (new), `references/dynatrace-docs/changelog-guidelines.md`, `references/escalation-rules.md`, `references/source-truth.md`, `references/dynatrace-docs/render-verification.md`, `references/dynatrace-docs/docs-profile.default.yml`, `references/dynatrace-docs/docs-profile-schema.md`, `agents/docs-style-checker.md`, `agents/doc-planner.md`, `agents/doc-writer.md`, `agents/doc-reviewer.md`, `commands/document.md`, `commands/docs-profile.md`
- Hand-edit (identity files — **never** `cp`): `plugins/dev-workflows/README.md`, `plugins/dev-workflows/CHANGELOG.md`, `plugins/dev-workflows/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `CLAUDE.md`

**Interfaces:**
- Consumes: the finished canonical tree.
- Produces: mgd at dev-workflows 2.43.0, with `diff -rq` against canonical reporting exactly five files.

**Context:** mgd's five identity files carry `Dynatrace Managed` / `Dynatrace-Internal` authorship, the `mgd-plugins` marketplace name, the `Dynatrace-Internal/mgd-ai-containers` container repo, a `Dynatrace LLC` copyright, and CHANGELOG entries annotated "(ported from `ihudak-claude-plugins`)". A blind `cp` of the tree clobbers three of them.

- [ ] **Step 1: Confirm the pre-port baseline**

```bash
cd /workspace
git -C mgd-claude-plugins status --porcelain | wc -l    # expect 0
diff -rq ihudak-claude-plugins/plugins/dev-workflows mgd-claude-plugins/plugins/dev-workflows
```
Expected, BEFORE copying: mgd is `0` dirty, and `diff -rq` reports **17 differing files plus 3 "Only in canonical" lines**. That set breaks down as: the **5 identity files** (`.claude-plugin/plugin.json`, `CHANGELOG.md`, `LICENSE`, `README.md`, `references/dependencies.md`), the **12 content files this feature changed** (the Step 2 list minus its 3 new files), and the **3 new references** as "Only in" lines. Identity files differ because they are mgd's own; content files differ because canonical has this feature and mgd does not yet.

Any file differing that is NOT in one of those three groups means canonical and mgd drifted independently — stop and report BLOCKED rather than copying over it.

**CORRECTED 2026-08-13 (R38, WRONG-TARGET):** "17 differing files plus 3 Only-in lines" (20 total) was never achievable on this repo pair. Re-derived at the paired pre-B1 baseline commits — canonical `29dff3f` (2.42.0) / mgd `aac4320` (A's port merge) — a plain `diff -rq` reports **50** differing items, not 20: on top of the 20 accounted for above, roughly 30 files under `references/guidelines/`, `references/api-guidelines/`, `references/fix-vuln/`, and `references/upgrade/` differ line-for-line because canonical's committed blobs use CRLF line endings and mgd's use LF for these files — confirmed at the raw git-blob level (`git show <commit>:<path>`, not a checkout artifact) and confirmed pre-existing (present before this sub-project's first commit, unrelated to gate-enforcement content). The check as written sweeps the whole `plugins/dev-workflows` tree instead of scoping to files this feature actually touches, so it was always wrong-target for this repo pair, not specific to any one sub-project's ship state.

- [ ] **Step 2: Copy the fifteen content files**

```bash
cd /workspace
SRC=ihudak-claude-plugins/plugins/dev-workflows
DST=mgd-claude-plugins/plugins/dev-workflows
for f in \
  references/gate-ledger.md \
  references/toolchain-preflight.md \
  references/repo-verification-gates.md \
  references/escalation-rules.md \
  references/source-truth.md \
  references/dynatrace-docs/changelog-guidelines.md \
  references/dynatrace-docs/render-verification.md \
  references/dynatrace-docs/docs-profile.default.yml \
  references/dynatrace-docs/docs-profile-schema.md \
  agents/docs-style-checker.md \
  agents/doc-planner.md \
  agents/doc-writer.md \
  agents/doc-reviewer.md \
  commands/document.md \
  commands/docs-profile.md ; do
  cp "$SRC/$f" "$DST/$f"
done
diff -rq "$SRC" "$DST"
```
Expected: exactly the five identity files differ, nothing else.

- [ ] **Step 3: Hand-edit mgd's README**

Apply the same two edits as canonical Task 10 Steps 1–2 (the two new reference bullets and the `/document` row addition) to `mgd-claude-plugins/plugins/dev-workflows/README.md`, **preserving** its `mgd-plugins` marketplace name and its `Dynatrace-Internal/mgd-ai-containers` container repo references. Copy the bullet text from canonical; do not copy the file.

- [ ] **Step 4: Hand-edit mgd's CHANGELOG**

Insert the same `## [2.43.0] — 2026-08-08` entry as canonical Task 10 Step 3 at the top of `mgd-claude-plugins/plugins/dev-workflows/CHANGELOG.md`, and append to its heading line the repo's existing annotation convention so it reads:

```markdown
## [2.43.0] — 2026-08-08 (ported from `ihudak-claude-plugins`)
```

Match the exact annotation format used by the neighbouring entries in that file — read one before writing.

- [ ] **Step 5: Bump mgd's two version locations**

Edit `mgd-claude-plugins/plugins/dev-workflows/.claude-plugin/plugin.json` by hand: `"version": "2.42.0"` → `"2.43.0"`. Leave its `author` and URL fields alone.

Edit `mgd-claude-plugins/.claude-plugin/marketplace.json` by hand: in the `dev-workflows` entry only, set `"version": "2.43.0"` and extend its `"description"` with the same sentence used in canonical Task 10 Step 4. Leave the other three entries untouched.

- [ ] **Step 6: Update mgd's root `CLAUDE.md`**

Apply the same additions as canonical Task 10 Step 5 (two Source-truth paragraphs, three `/document` invariants) to `mgd-claude-plugins/CLAUDE.md`, preserving any mgd-specific wording already in that file.

- [ ] **Step 7: Verify the port**

```bash
cd /workspace
echo "--- exactly five identity files differ ---"
diff -rq ihudak-claude-plugins/plugins/dev-workflows mgd-claude-plugins/plugins/dev-workflows | tee /tmp/mgd-diff.txt | wc -l
grep -c "plugin.json\|CHANGELOG.md\|LICENSE\|README.md\|dependencies.md" /tmp/mgd-diff.txt
echo "--- mgd identity preserved ---"
grep -c "mgd-plugins" mgd-claude-plugins/plugins/dev-workflows/README.md
grep -c "Dynatrace" mgd-claude-plugins/plugins/dev-workflows/LICENSE
grep -c "ported from" mgd-claude-plugins/plugins/dev-workflows/CHANGELOG.md
echo "--- versions ---"
python3 -c "
import json
print(json.load(open('mgd-claude-plugins/plugins/dev-workflows/.claude-plugin/plugin.json'))['version'])
d=json.load(open('mgd-claude-plugins/.claude-plugin/marketplace.json')); ps=d.get('plugins',d)
print([p['version'] for p in ps if p['name']=='dev-workflows'][0])
print('siblings:', [(p['name'],p['version']) for p in ps if p['name']!='dev-workflows'])
"
```
Expected: `5` differing files, all five matching the identity list; non-zero counts for each identity marker; `2.43.0` twice; siblings unchanged.

**CORRECTED 2026-08-13 (R38, WRONG-TARGET):** "5 differing files" was never achievable by this literal command on this repo pair, for the same reason as the Step 1 baseline above. Re-derived at the ship commits (canonical `c7bdac2`, mgd `fce902f`, via `git show <commit>:<path>` to bypass any local checkout normalization): `diff -rq` reports **47** differing items, not 5 — the 5 identity files plus the same ~30-40 pre-existing CRLF-vs-LF `references/guidelines/` `references/api-guidelines/` `references/fix-vuln/` `references/upgrade/` files identified in the Step 1 correction, unrelated to this feature. The 5 identity files themselves are confirmed correct (`grep -c` against `/tmp/mgd-diff.txt` for the identity filenames still isolates exactly those 5 among the noise); it is the bare `wc -l` total that the check should never have keyed on.

- [ ] **Step 8: Commit**

```bash
cd /workspace/mgd-claude-plugins
git add -A
git commit -m "feat(dev-workflows): 2.43.0 — /document gate enforcement (ported)

Ports the Phase 0 toolchain preflight, the gate ledger, the linter ladder
fall-through, per-space profile commands, changelog-guidelines wiring,
repo pre-PR checklist ingestion, the commands/CLI claim class, and the
render-gate repair from ihudak-claude-plugins. The five mgd identity files
were hand-edited, not copied.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 12: Port to ihudak-copilot-plugins

**Files (in `/workspace/ihudak-copilot-plugins`):**
- Create: `dev-workflows/skills/_shared/gate-ledger.md`, `dev-workflows/skills/_shared/toolchain-preflight.md`, `dev-workflows/skills/_shared/repo-verification-gates.md`
- Modify: `dev-workflows/skills/_shared/escalation-rules.md`, `source-truth.md`, `dynatrace-docs/changelog-guidelines.md`, `dynatrace-docs/render-verification.md`, `dynatrace-docs/docs-profile.default.yml`, `dynatrace-docs/docs-profile-schema.md`
- Modify: `dev-workflows/agents/docs-style-checker.md`, `doc-planner.md`, `doc-writer.md`, `doc-reviewer.md`
- Modify: `dev-workflows/skills/document/SKILL.md`, `dev-workflows/skills/docs-profile/SKILL.md`
- Modify: `dev-workflows/README.md`, `dev-workflows/CHANGELOG.md`, `dev-workflows/.plugin/plugin.json`
- Modify: `.github/plugin/marketplace.json`, `.github/copilot-instructions.md`

**Interfaces:**
- Consumes: the finished canonical tree.
- Produces: copilot at dev-workflows 2.13.0 with no Claude-only token surviving.

**Context:** copilot's `skills/_shared/` mirrors canonical `references/` one-for-one, including the `dynatrace-docs/` subdirectory, and `skills/document/SKILL.md` tracks `commands/document.md` within about two lines. So this is a path-and-dispatch adaptation, not a restructure. **`.github/plugin/marketplace.json` and `.github/copilot-instructions.md` were both missed in the 2.42.0 port** — neither is optional here.

- [ ] **Step 1: Confirm the pre-port baseline**

```bash
cd /workspace
git -C ihudak-copilot-plugins status --porcelain | wc -l    # expect 0
python3 -c "
import json
print('plugin.json:', json.load(open('ihudak-copilot-plugins/dev-workflows/.plugin/plugin.json'))['version'])
d=json.load(open('ihudak-copilot-plugins/.github/plugin/marketplace.json')); ps=d.get('plugins',d)
print('catalog:', [p['version'] for p in ps if p['name']=='dev-workflows'][0])
"
```
Expected: `0` dirty files; both reading `2.12.0`.

- [ ] **Step 2: Port the two new references with adapted paths**

Copy each canonical file, then rewrite its internal citations:

```bash
cd /workspace
SRC=ihudak-claude-plugins/plugins/dev-workflows
DST=ihudak-copilot-plugins/dev-workflows
COPILOT_ROOT='~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared'
for f in gate-ledger.md toolchain-preflight.md repo-verification-gates.md ; do
  sed "s|\${CLAUDE_PLUGIN_ROOT}/references|$COPILOT_ROOT|g" "$SRC/references/$f" > "$DST/skills/_shared/$f"
done
grep -c 'CLAUDE_PLUGIN_ROOT' "$DST/skills/_shared/gate-ledger.md" "$DST/skills/_shared/toolchain-preflight.md" "$DST/skills/_shared/repo-verification-gates.md"
```
Expected: `0` for all three files.

- [ ] **Step 3: Port the modified references and agents**

For each of `escalation-rules.md`, `source-truth.md`, `dynatrace-docs/changelog-guidelines.md`, `dynatrace-docs/render-verification.md`, `dynatrace-docs/docs-profile.default.yml`, `dynatrace-docs/docs-profile-schema.md`, apply the **same edits** made in Tasks 1, 2, 6, 7, and 9 to the copilot copy under `dev-workflows/skills/_shared/`, rewriting any `${CLAUDE_PLUGIN_ROOT}/references/` citation to the copilot `_shared` path. Do not `cp` these — they may already carry copilot-specific path text.

For each of `agents/docs-style-checker.md`, `doc-planner.md`, `doc-writer.md`, `doc-reviewer.md`, apply the same edits made in Tasks 4, 5, 7, 8, and 9, with two adaptations: `${CLAUDE_PLUGIN_ROOT}/references/X` → the copilot `_shared` path, and any `subagent_type:` dispatch → `task(agent_type: …)`. Agent frontmatter `tools:` lists stay in their existing copilot lowercase form — do not change them.

- [ ] **Step 4: Port the two skills**

Apply the Task 3, 4, 5, 6, and 9 edits to `dev-workflows/skills/document/SKILL.md`, and the Task 2 Step 4 edit to `dev-workflows/skills/docs-profile/SKILL.md`. The phase headings match canonical (`## Phase 6.4 — Style check (before reviewer)`, `## Phase 6.5 — Render verification`, `### Readiness`, `## Invariants (always enforced)`), so anchor on those. Rewrite every reference citation to the copilot `_shared` path, and convert `→ Agent (subagent_type: "dev-workflows:X", model: …)` to `→ task(agent_type: "dev-workflows:X", model: …)`.

- [ ] **Step 5: Index the new references in copilot's README**

Copilot has no repo-root `CLAUDE.md`; its reference index lives in `dev-workflows/README.md`'s `_shared` list. Insert the same two bullets from canonical Task 10 Step 1 there, adapting the paths to `skills/_shared/gate-ledger.md` and `skills/_shared/toolchain-preflight.md`. Place them near the most recently added related entry, following that list's existing grouping.

- [ ] **Step 6: Update `.github/copilot-instructions.md`**

This is copilot's `CLAUDE.md` counterpart and was missed in 2.42.0. Apply the equivalent of canonical Task 10 Step 5: add the two source-truth paragraphs (with `skills/_shared/…` paths) and the three `/document` invariants. Read the file's existing section structure first and match it — its headings differ from `CLAUDE.md`'s.

- [ ] **Step 7: CHANGELOG and both version locations**

Add a `## [2.13.0] — 2026-08-08` entry to `dev-workflows/CHANGELOG.md` mirroring canonical's 2.43.0 entry, adapted to copilot terminology (skills rather than commands, `task(agent_type:)` rather than `Agent`), and matching the annotation convention of its neighbouring entries.

Edit `dev-workflows/.plugin/plugin.json` by hand: `"2.12.0"` → `"2.13.0"`.

Edit `.github/plugin/marketplace.json` by hand: in the `dev-workflows` entry only, set `"version": "2.13.0"` and extend its `"description"` with the same sentence used in canonical Task 10 Step 4. Leave the other entries untouched.

- [ ] **Step 8: Verify no Claude-only token survives**

<!-- CORRECTED 2026-08-13 (R38, WRONG-TARGET): "expect 0 lines" was unsatisfiable on any tree at or after ship commit a536b07 — the whole-tree sweep also matches `dev-workflows/CHANGELOG.md`, which legitimately narrates the copilot/canonical dialect contrast using the very tokens being banned (one line added by a536b07 itself: "no CLAUDE_PLUGIN_ROOT tokens"; one pre-existing from commit cb9e8cf: "instead of `${CLAUDE_PLUGIN_ROOT}`"). Re-derived at a536b07: raw sweep = 2 lines, both CHANGELOG.md prose, zero in actual skill/agent content. Old expected: "0 lines" (wrong-target — CHANGELOG narration was never excluded). Correct check excludes CHANGELOG.md: `grep -rn 'CLAUDE_PLUGIN_ROOT\|subagent_type' dev-workflows/ | grep -v '^dev-workflows/CHANGELOG.md'` → 0, confirming no real leak. -->
```bash
cd /workspace/ihudak-copilot-plugins
echo "--- Claude-only tokens in copilot content, excluding CHANGELOG.md narration (expect 0 lines) ---"
grep -rn 'CLAUDE_PLUGIN_ROOT\|subagent_type' dev-workflows/ | grep -v '^Binary' | grep -v '^dev-workflows/CHANGELOG.md' || echo "clean"
echo "--- new references present and indexed ---"
test -f dev-workflows/skills/_shared/gate-ledger.md && test -f dev-workflows/skills/_shared/toolchain-preflight.md && test -f dev-workflows/skills/_shared/repo-verification-gates.md && echo "all three present"
grep -c "gate-ledger.md" dev-workflows/README.md
grep -c "gate-ledger\|toolchain-preflight" .github/copilot-instructions.md
echo "--- versions (expect 2.13.0 twice) ---"
python3 -c "
import json
print(json.load(open('dev-workflows/.plugin/plugin.json'))['version'])
d=json.load(open('.github/plugin/marketplace.json')); ps=d.get('plugins',d)
print([p['version'] for p in ps if p['name']=='dev-workflows'][0])
print('siblings:', [(p['name'],p['version']) for p in ps if p['name']!='dev-workflows'])
"
echo "--- json valid ---"
python3 -c "import json;[json.load(open(f)) for f in ['.github/plugin/marketplace.json','dev-workflows/.plugin/plugin.json']];print('json ok')"
echo "--- key edits landed in the skill ---"
grep -c "toolchain-preflight" dev-workflows/skills/document/SKILL.md
grep -c "gate_ledger" dev-workflows/skills/document/SKILL.md
grep -c "go to step 5" dev-workflows/agents/docs-style-checker.md     # expect 0
```
Expected: `clean`; `all three present`; non-zero index counts in **both** the README and `copilot-instructions.md`; `2.13.0` twice with siblings unchanged; `json ok`; non-zero skill counts; and `0` for the step-5 jump.

- [ ] **Step 9: Commit**

```bash
cd /workspace/ihudak-copilot-plugins
git add -A
git commit -m "feat(dev-workflows): 2.13.0 — /document gate enforcement (ported)

Ports the Phase 0 toolchain preflight, the gate ledger, the linter ladder
fall-through, per-space profile commands, changelog-guidelines wiring,
repo pre-PR checklist ingestion, the commands/CLI claim class, and the
render-gate repair, adapted to the Copilot layout: skills/_shared paths,
task(agent_type:) dispatch, no CLAUDE_PLUGIN_ROOT tokens. Both the
marketplace catalog and .github/copilot-instructions.md are updated —
each was missed in the 2.42.0 port.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Plan self-review

**Spec coverage** — every spec section maps to a task: §1 preflight → Tasks 1, 3; §2.1–2.3 ledger schema → Task 1; §2.4 registry → Tasks 1, 5; §2.5 reviewer contract → Task 5; §2.6 Phase 9 → Task 5; §2.7 `UNAVAILABLE` conversion → Tasks 1, 5; §2.2 verbatim rule → Tasks 1, 6; §3 linter ladder → Task 4; §4 changelog wiring → Task 7; §5 checklist + profile → Tasks 2, 8; §6.1 claim class → Task 9; §6.2 supplementary grep → Task 9; §7 render gate → Task 6. Spec Files-changed table: all 17 canonical entries appear across Tasks 1–10. Spec verification list items 1–12 appear as executable checks in Tasks 3, 5, 6, 7, 9, 10, 11, 12.

**Interface consistency** — the outcome names (`RAN` / `DEGRADED` / `FAILED` / `UNAVAILABLE` / `SKIPPED_BY_USER` / `NOT_APPLICABLE`), the six gate ids, and the field names (`not_run`, `ci_still_checks`, `precondition_unmet`, `user_decision`, `findings`, `primary_attempts`, `spaces`, `repo_verification_gates`, `commands.per_space`) are spelled identically in Task 1's contract and in every consuming task.

**Two spec gaps closed here, both flagged to the reviewer:**
1. **Direct mode has no profile.** Its Phase 0 is only "Load the description" and Phase 3.5 uses cwd's git root, so `toolchain-preflight.md` §2 explicitly scopes direct mode to sources 2–3 and Task 3 Step 3 resolves `repo_root` itself.
2. **Direct mode has no build or render gate**, so `gate-ledger.md` §4 states that those three gate ids never appear in a direct-mode ledger — not even as `NOT_APPLICABLE` — which the Task 5 reviewer contract would otherwise flag as missing rows.

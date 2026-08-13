# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this repo is

A private Claude Code plugin marketplace hosted at `github.com/ihudak/ihudak-claude-plugins`.
Registered in `~/.claude/plugins/known_marketplaces.json` as `ihudak-plugins`.

## Structure

```
.claude-plugin/marketplace.json   ← plugin catalog (do not reformat; Claude Code parses it)
plugins/
  <plugin-name>/
    .claude-plugin/plugin.json    ← required: name, description, author
    README.md
    LICENSE
    commands/                     ← slash commands (.md files)
    agents/                       ← subagent system prompts (.md files, YAML frontmatter required)
    hooks/
      hooks.json                  ← hook declarations; use ${CLAUDE_PLUGIN_ROOT} for paths
      *.sh                        ← hook scripts
    skills/                       ← skills (.md files), if any
    references/                   ← vendored reference docs the commands consult
```

## Active plugin: dev-workflows

`plugins/dev-workflows/` provides twenty-one slash commands — `/implement`, `/document`, `/docs-profile`, `/epics`, `/release-notes`, `/vuln`, `/upgrade`, `/api-guideline-reviewer`, `/guideline-reviewer`, `/idea`, `/create-vi`, `/create-ard`, `/specify`, `/design`, `/feedback`, `/prompt`, `/prompt-brainstorm`, `/prompt-grill-me`, `/statusline`, `/ready`, and `/update-vi` — plus thirty-three reusable subagents, four hooks, and reference docs.

The live `dev-workflows` workflow relies on a larger set of helper agents and
workflow roles; see the taxonomy and workflow map below.

**Internal reference convention:**
- Agents are invoked by `subagent_type` (`<plugin>:<agent>`, e.g. `dev-workflows:risk-planner`) — never by reading the agent file. Claude Code loads the agent body as its system prompt and honours its `model:` frontmatter.
- Inside **agent** and **skill** bodies (and `hooks.json` / MCP / monitor configs), reference bundled files via `${CLAUDE_PLUGIN_ROOT}/...`. This variable does NOT expand in slash-command bodies.
- Slash **commands** that need bundled reference content (e.g. model-routing classification) invoke a skill that resolves `${CLAUDE_PLUGIN_ROOT}` on their behalf (see the `model-routing` skill).
Do NOT hardcode `~/.claude/plugins/data/...@.../` paths — that directory holds only empty per-plugin state; installed content lives under `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`.

**When editing `dev-workflows`:** update the files in `plugins/dev-workflows/` directly.
Do NOT edit `~/.claude/claude-config/` — that repo is retired and will be deleted.

## Adding a new plugin

1. Create `plugins/<name>/` with `.claude-plugin/plugin.json`.
2. Add content directories (`commands/`, `agents/`, `hooks/`, etc.).
3. For hooks: create `hooks/hooks.json` using `${CLAUDE_PLUGIN_ROOT}` for all paths.
4. Register in `.claude-plugin/marketplace.json` with `"source": "./plugins/<name>"`.
5. Commit and push to `main`. Claude Code picks up changes on next sync/reinstall.

## Conventions

- Agent `.md` files must start with YAML frontmatter (`---`) containing at minimum `name` and `description`.
- Hook scripts must exit 0 — they must never block Claude.
- `hooks.json` `matcher` field (for PostToolUse) goes at the entry level, not inside the hook object.
- Plugin content references bundled files via `${CLAUDE_PLUGIN_ROOT}` (agents/skills/hooks) or the `model-routing` skill (commands); never hardcode `~/.claude/plugins/data/...@.../` paths (see the Internal reference convention above).
- MIT license applies to all plugins unless a plugin directory has its own LICENSE file.

## Command, agent, and skill taxonomy

### Commands

User-facing slash commands live under `commands/`. They own the end-to-end
workflow, gather context, decide whether to branch, test, or review, and may
dispatch helper agents via the `task` tool.

### Agents

Helper agents live under `agents/`. They are Claude Code sub-agent system
prompts, not user entry points. Each agent does one bounded job — planning,
research, review, fixing, test writing, Jira reading, or maintenance — and
returns its result to the invoking command.

### Skills

Optional reusable guidance lives under `skills/`. A skill is neither a command
nor an agent: it packages durable instructions or domain knowledge that multiple
commands or agents may consult. If a plugin has no `skills/`, keep shared
runtime docs under `references/`.

### Working rule

Commands orchestrate. Agents execute bounded tasks. Skills provide reusable
knowledge. Keep those roles separate so workflows stay predictable.

## Model routing reference

`plugins/dev-workflows/references/model-routing/classification.md` is the
**single source of truth** for:

- Task complexity classification (`SIMPLE` / `MODERATE` / `SIGNIFICANT` /
  `HIGH-RISK`)
- The model fallback chain (Opus 5 → 4.8 → 4.7 → 4.6 → Sonnet 5 → Sonnet 4.6 → Sonnet 4.5)
- The mandatory Opus code-review checklist
- The `model_routing` YAML handoff block shared between commands and agents
- The `phase: verify-resume` protocol for review-gated verification
- The large-input scan fan-out policy (§8): the input-shape trigger, the `jira-reader → parallel code-scanner (cap 4) → Opus synthesis` pattern, the SIGNIFICANT floor it imposes, and §8.5's opt-in seeded second round (adopted by `/idea` and `/implement`) with its rule that an unresolved theme is named, never flattened into a gap

All pipeline commands that invoke the `model-routing` skill (`/implement`, `/document`,
`/epics`, `/release-notes`, `/vuln`, `/upgrade`, `/docs-profile`, `/idea`, `/create-vi`,
`/update-vi`, `/create-ard`, `/specify`, `/design`, `/ready`) must load and follow this file at the
start of every invocation. The standalone review commands (`/api-guideline-reviewer`,
`/guideline-reviewer`) and the feedback / utility commands (`/feedback`, `/prompt`,
`/prompt-brainstorm`, `/prompt-grill-me`, `/statusline`) are exempt. Agents receive the `model_routing` block
in their prompt; they do not re-read the file.

## Source-truth reference

`plugins/dev-workflows/references/source-truth.md` is the **single source of truth** for the Implementation-vs-Description discrepancy-escalation protocol. It is consulted by `doc-planner`, `doc-writer`, `doc-reviewer`, `release-notes-writer`, and `risk-planner` to verify user-visible claims (option lists, UI labels, menu paths, defaults, counts, mode names) against the shipped source code, and defines the escalation protocol when Jira and source disagree (Phase 5.8 in `/document` (Jira mode)).

`plugins/dev-workflows/references/release-note-types.md` is the **single source of truth** for the release-note **destination map** (`breaking-changes.md` / `feature-updates.md` / `fixes.md`), the per-destination **draft shape** (label + title + prose, vs one bare sentence for `fixes`), the per-destination prose rules, the deprecation-note rule (end-of-life date required, end-of-support optional), and Change Type sourcing (import → infer). It is consulted by `release-notes-writer`; the Change Type is never rendered as text.

`plugins/dev-workflows/references/docs-grounding.md` is the **single source of truth** for `$DOCS_PATH` documentation grounding — the resolution gate (`${DOCS_PATH:-/workspace/docs}`, read-only, silent-skip), the `resolve-docs-grounding` procedure, and the grill-rank / writer-attach consumption modes; consumed by the seven authoring commands (`/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/epics`, `/release-notes`) — not `/document`.

`plugins/dev-workflows/references/vault-prior-art.md` is the **single source of truth** for vault prior-art discovery — the `resolve-prior-art` / `dispatch-prior-art-finder` entry points, the search scope (`Projects/Products/**`, `Projects/ideas/**`) and its exclusions (`Jira - <KEY>/` snapshots, Value Packs, `_archive/`), the status-resolution ladder (work-doc frontmatter before the export, disagreements reported not resolved) with its short-code map, the container derivation shared by `/idea`'s write-path default and `area_proposal`, and the bounding caps. Consumed by `/idea` and `/create-vi`. Read-only and advisory — never a gate; there is no retrieval index and therefore no consent gate.

`plugins/dev-workflows/references/prose-formatting.md` is the **single source of truth** for output line-wrapping — never hard-wrap prose; write each paragraph/prose block as one unbroken line, so Obsidian and IntelliJ Idea soft-wrap it for reading and a straight copy-paste into Jira/Grammarly needs no manual cleanup. Consumed by every authoring command/agent that writes prose (`/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/design`, `epic-writer`, `doc-writer`, `release-notes-writer`).

`plugins/dev-workflows/references/bug-diagnosis.md` is the **single source of truth** for the bug-diagnosis discipline consulted by `/implement` (Phase 2B) and followed by `risk-planner` when a task is bug-shaped (`task_shape: bug`): feedback-loop-first (a red-capable, deterministic repro before hypothesizing), 3–5 ranked falsifiable hypotheses, `[DEBUG-xxxx]`-tagged instrumentation with a mandatory cleanup gate (stripped before the Opus-review diff), and a regression test at a correct seam. It cross-references `references/design-format.md` `## Seams` for the seam vocabulary and is paired with `/implement`'s spec/design-conformance ("converge") check — `code-review`'s conditional 10th dimension that traces in-scope `[Uxx]`/`[ACxx]`/`[TCxx]` against the shipped diff.

`plugins/dev-workflows/references/specs-repo-git.md` is the **single source of truth** for the two git entry points the plugin runs against `$SPECS_PATH` — `specs-preflight` (run start: flush leftover artifacts, retry an unpushed artifact commit, settle the branch) and `commit-artifacts` (terminal: stage the bounded artifact paths, commit, push). It owns the bounded write authority (three path shapes; `^(vi|ard|spec|design)/` branches only), the three guards and their four-part notice contract, the branch-disposition table, and the `Specs repo:` outcome line. Consumed by the seventeen commands that write into `$SPECS_PATH` — every command except `/api-guideline-reviewer`, `/guideline-reviewer`, `/statusline`, and `/docs-profile`. Hard rules: every git call is `git -C "$SPECS_PATH"` and never a `cd`; `git add -A` is never issued at repository scope; never force-push, never `branch -D`, never merge/rebase/reset, never delete an `index.lock`; never fatal.

`plugins/dev-workflows/references/read-only-repos.md` is the **single source of truth** for read-only repository mounts — the detection probe (`test -w` on the repo and `.git`, plus the `Read-only file system` error as a secondary trigger), what read-only mode skips (`fetch`/`pull`/`switch`/`remote set-head`, and the dirty-tree gate), write-free ref resolution and reading (`ls-tree`, `git grep <ref>`, `git show <ref>:<path>`), the 14-day staleness / ahead-of-ref escalation trigger, and the `prep` output contract (`read_only`, `scanned_ref`, `ref_committed_at`, `head_divergence`). Consumed by `code-scanner`, `diff-summarizer`, and `docs-grounder`, and cited by the seven commands that dispatch them. Writable mounts are unaffected: `git switch` and `git pull --ff-only` remain sanctioned prep on a writable clone.

`plugins/dev-workflows/references/gate-ledger.md` is the **single source of truth** for verification-gate accounting — the six outcomes (`RAN` / `DEGRADED` / `FAILED` / `UNAVAILABLE` / `SKIPPED_BY_USER` / `NOT_APPLICABLE`), the rule that **no outcome is orchestrator-assignable to mean "I decided not to run this"**, the `/document` gate registry, the `UNAVAILABLE` conversion prompt, and the reviewer contract. Consumed by `/document` (both modes) and written generically for other commands to adopt.

`plugins/dev-workflows/references/repo-verification-gates.md` is the **single source of truth** for extracting a docs repo's own pre-PR checklist into the `repo_verification_gates` block — the heading patterns, what counts as checkable against the written files, and the augment-never-override rule. Applied by `doc-planner` in `/document` Jira mode and by the orchestrator itself in direct mode, which has no planner.

`plugins/dev-workflows/references/toolchain-preflight.md` is the **single source of truth** for the Phase 0 environment check — deriving the required tool set from the resolved profile, the repo's config signals, and the repo's own documented `Prerequisites`; the `toolchain` block with its tool→gate map; and the missing-tool prompt (Cancel recommended, silence when everything resolves). Consumed by `/document` (both modes).

`plugins/dev-workflows/references/doc-structure-conventions.md` is the **single source of truth** for three product-docs authoring conventions: the traceability boundary (a rendered page carries no Jira key, PR URL, or provenance comment — that lives in the commit message and the run handoff only), callout scope and adjacency (a callout sits with the option it qualifies, in the lead-in only when it spans the whole set), and component-pattern fidelity (reuse an area's established content component for a recurring content shape instead of an ad-hoc structure). Consumed by `doc-planner`, `doc-writer`, and `doc-reviewer`.

## `dev-workflows` workflow relationships

```
/implement           → [Pre-Phase 2 scale assessment] → (multi-source? → [jira-reader → code-scanner×N (parallel, cap 4) → §8.5 narrow round 2] → synthesis, unresolved themes named) → [risk-planner@Opus plan critique] → [code-review@Opus] → review-fixer → test-writer → tests → impl-maintenance → commit-artifacts
/document (direct)   → [docs-style-checker] → [doc-fixer] → impl-maintenance → commit-artifacts
/docs-profile        → scans docs repo → writes/refreshes .dev-workflows/docs-profile.yml + CLAUDE.md guidance → PR
/document (Jira)     → jira-reader → [diff-summarizer×N (parallel)] → [doc-location-finder] → [counterpart-finder (space-constrained runs)] → [doc-planner] → [discrepancy-escalation (Phase 5.8)] → writing → [docs-style-checker → dt-style-checker fallback] → [doc-fixer] → [doc-reviewer] → [doc-fixer] → impl-maintenance → commit-artifacts   (Phase 0 hint: prefers ${DOCS_PATH:-/workspace/docs} as a docs-repo discovery hint — write-target only, no docs-grounder consumption)
/epics               → jira-reader → [code-scanner×N (parallel, optional)] → [docs-grounder] → writing → [dt-style-checker] → [doc-fixer] → [epic-reviewer@Opus] → [doc-fixer] → impl-maintenance → commit-artifacts
/release-notes       → jira-reader → [diff-summarizer×N (parallel, optional)] → [docs-grounder] → [release-notes-writer: resolve destination + shape per destination + source the {{#context}} label + detect deprecation] → [dt-style-checker → dt-doc-fixer (optional)] → write draft (destination-shaped Summary; paste into Jira) → commit-artifacts
/vuln                → vuln-research → vuln-fixer → [code-review@Opus] → review-fixer → tests → impl-maintenance → commit-artifacts
/upgrade             → upgrade-planner → [risk-planner@Opus] → upgrade-executor → [code-review@Opus] → review-fixer → tests → impl-maintenance → commit-artifacts
/idea                → idea-reader → [docs-grounder (when $DOCS_PATH valid) + vault-prior-art-finder (when prior art ON)] → [code-scanner×N (--ground-code, cap 4, broad-then-narrow)] → (embedded grilling) → write idea.md → commit-artifacts
/create-vi           → [docs-grounder + vault-prior-art-finder] → (embedded grilling) → [vi-reviewer@Opus] → write VI + relocate idea.md → commit-artifacts
/update-vi           → [Jira-import-first resolve] → [docs-grounder] → (embedded grilling, diffs against base) → [vi-reviewer@Opus] → write canonical + archived revisions → commit-artifacts
/create-ard          → [jira-reader (Epic-level always; VI-level only if the authored VI file is absent under $SPECS_PATH)] → [ls $REPOS_PATH → code-scanner×N (confirmed set, parallel, cap 4)] → [docs-grounder] → (embedded grilling) → [ard-reviewer@Opus] → write ARD → commit-artifacts
/specify             → jira-reader → [code-scanner×N (parallel, cap 4, soft gate)] → [docs-grounder] → (embedded grilling) → [spec-reviewer@Opus] → write specification.md → commit-artifacts
/design              → [code-scanner×N (parallel, cap 4, STRICT gate)] → (embedded grilling, challenges spec) → [design-reviewer@Opus] → write design.md → commit-artifacts
/ready               → jira-reader + Jira status read → verify ARD/spec/design → [readiness-reviewer@Opus] → SUPPORTED/PARTIAL/NOT-SUPPORTED → impl-maintenance + emit-auto → commit-artifacts
All seventeen in-scope commands additionally run `specs-preflight` at run start — as early as `$SPECS_PATH` is known (Phase 0 in most commands, Step 0 in `/vuln`, the shared `## Mode detection` section in `/document`) — and `commit-artifacts` as their last action (`references/specs-repo-git.md`) — including `/feedback`, `/prompt`, `/prompt-brainstorm`, and `/prompt-grill-me`, which have no line of their own in this map because they are single-purpose logging commands rather than pipelines. In `/prompt-brainstorm` and `/prompt-grill-me` the terminal step runs immediately before their Phase 3, which cedes the session (`references/specs-repo-git.md` §4).
                      └── test-baseliner      (used by /implement, and by /upgrade and /vuln both directly and via upgrade-executor / vuln-fixer)
                      └── test-writer        (used by /implement only)
                      └── risk-planner       (used by /implement plan critique, /upgrade)
                      └── code-review        (used by /implement, /vuln, /upgrade)
                      └── doc-reviewer       (used by /document)
                      └── doc-fixer          (used by /document, /epics)
                      └── doc-location-finder (used by /document Jira mode)
                      └── counterpart-finder (used by /document Jira mode, space-constrained runs)
                      └── doc-planner        (used by /document Jira mode)
                      └── docs-style-checker (used by /document, both modes)
                      └── epic-reviewer      (used by /epics)
                      └── code-scanner       (used by /epics, /implement multi-source fan-out, /create-ard, /specify, /design, /idea)
                      └── jira-reader        (used by /document, /epics, /release-notes, /implement multi-source fan-out, /create-ard, /specify, /ready)
                      └── vi-reviewer         (used by /create-vi, /update-vi)
                      └── ard-reviewer        (used by /create-ard)
                      └── spec-reviewer       (used by /specify)
                      └── design-reviewer     (used by /design)
                      └── readiness-reviewer  (used by /ready)
                      └── idea-reader         (used by /idea)
                      └── docs-grounder       (used by /idea, /create-vi, /update-vi, /create-ard, /specify, /epics, /release-notes)
                      └── vault-prior-art-finder (used by /idea, /create-vi)
/api-guideline-reviewer → standalone command; reviews OpenAPI specs against Dynatrace REST API + IAM guidance
/guideline-reviewer     → standalone command; reviews code/UI against Dynatrace Experience Standards
```

## Key invariants

Key invariants enforced by all three code-oriented commands:

- Branch created before any file is touched (`feat/<slug>` or equivalent)
- Opus review gate runs **before** tests for `SIGNIFICANT` / `HIGH-RISK` tasks
- `review-fixer` handles BLOCKER findings; only one `review-fixer` cycle per review
- `impl-maintenance` runs post-batch to update KB, `CLAUDE.md`, and project docs
- Every command that writes into `$SPECS_PATH` runs `specs-preflight` at run start — as early as `$SPECS_PATH` is known (Phase 0 in most commands, Step 0 in `/vuln`, the shared `## Mode detection` section in `/document`) — and `commit-artifacts` as its last action, or immediately before a phase that cedes control (`references/specs-repo-git.md` §4) — bounded to the artifact paths and to plugin-created branches, and reported once as a `Specs repo:` line

Key invariants for `/implement` specifically:

- Test baseline captured **before** any source edits, using `test-baseliner`
- `test-writer` writes tests for **new or changed behaviour** — mandatory for code changes
- If no test framework is detected, surface that explicitly — test-writing is never silently skipped
- Full test suite is verified against the captured baseline before the workflow is considered complete
- Multi-source input (more than one repo, or any directory input — Jira ticket folder or spec folder) floors classification at SIGNIFICANT (overridable at plan approval) and triggers the Phase 1.7 fan-out scan
- The fan-out runs `jira-reader` + per-repo `code-scanner` (single response, cap 4 concurrent); its synthesized summary feeds the planner instead of the single Explore subagent
- A theme round 1 leaves inconclusive — `partial`/`absent`/`error`, or two scanners each naming the other's repo — gets ONE narrow round 2 seeded with round 1's verified anchors (`classification.md` §8.5, cap 4, no round 3). A theme still unresolved after round 2 is named in the summary's `## Unresolved` section and carried into the plan's risks; it is NEVER flattened into an ordinary gap, because a gap asserts absence while an unresolved theme asserts only that the scan could not tell
- A referenced directory that is missing or unrecognized is surfaced, never silently skipped

Key invariants for `/document` (direct mode):

- **No branch creation by default** — it works on the current branch unless the user requests one
- **No `test-baseliner`, no `test-writer`, no `code-review`** — docs-only phases only
- **No `doc-reviewer` gate** — direct mode is deliberately lightweight: a mandatory style check (Phase 3.5) and `doc-fixer`, but no Opus review. Two rules in `document.md` (`:1490`, `:1494`) depend on that absence
- Style-check findings are fixed via `doc-fixer`; with no reviewer gate there is no BLOCKER fix cycle and no re-review in this mode
- Mixed code + docs changes must use `/implement` instead

Key invariants for `/document` (Jira mode) and `/epics`:

- `/document` (Jira mode) and `/epics` are distinct top-level commands, each invoked explicitly
- **Zero direct API calls** — PR URLs from Jira exports are identifiers only; the agent never calls the GitHub or Bitbucket REST API **directly over HTTPS**. GitHub resolution may use the `gh` CLI (which wraps the API — allowed); Bitbucket has no `gh` and is pure local `git`; all resolution runs against clones discovered under `$REPOS_PATH` (default `/workspace`), matched by `git remote get-url origin` slug
- `jira-reader` is strictly read-only — it never modifies vault files
- Parallel agent invocation: all diff summarizers (docs flow) or code scanners (epics flow) are launched in a **single response**
- Branch setup happens **before** writing output files — never after
- Branch policy: `/epics` never branches. `/document` classifies its write context against the resolved `docs_repo_path` (not necessarily cwd) — walk up for `.obsidian/` → `obsidian` (never branch); else `git rev-parse` plus docs signals → `docs_repo` (branch opt-in, confirmed at plan approval) or `non_docs_repo` (user confirmation promotes it to `docs_repo` behaviour); else `plain_dir` (never branch)
- `doc-location-finder` (docs flow) identifies write targets before writing begins
- Counterpart-space grounding (`counterpart-finder`, Phase 5.6.5) runs only on space-constrained runs; it is **read-only** — never copies counterpart-space-specific detail or screenshots into the target doc; `--counterpart <JiraID|PR-url>` reaches an unmerged counterpart PR by reusing `/document`'s existing PR-diff resolver (`diff-summarizer`, no new external-API surface); nothing found ⇒ the run behaves exactly as today
- `doc-planner` (docs flow) synthesizes Jira + diffs into a documentation checklist
- `docs-style-checker` + `doc-fixer` lint prose after writing, before the review gate; style check is mandatory — falls back to `dt-style-checker`; `NOT_CONFIGURED` only when nothing is available
- For epics, `dt-style-checker` is the primary style checker; skip gracefully if `dt-style-guide` is not installed
- Jira-vs-source discrepancies are escalated in Phase 5.8 (never auto-resolved); `doc-planner` records both `jira_phrasing` and `source_phrasing` without choosing
- A bug-report draft (`<KEY>-implementation-gaps.md`) is written to the vault project folder for `document-as-spec` / `skip-and-report` decisions, and for a `document-as-code` decision where the Jira phrasing asserts a specific value the source contradicts (`references/source-truth.md` §7.5)
- Review gate is `doc-reviewer` (docs flow) or `epic-reviewer@Opus` (epics flow); `doc-fixer` resolves BLOCKERs; cap at one fix cycle plus one re-review
- Sub-agents return `DIRTY_TREE` / `REFRESH_BLOCKED` when a **writable** repo cannot be refreshed; a read-only mount returns neither and scans at `prep.scanned_ref` — never fail silently
- Every written claim must cite the originating Jira key (`[[KEY]]`) plus PR URL (docs flow) or file path (epics flow)
- Writes never touch `_archive/` and never write outside cwd unless the user provides an explicit absolute path
- (docs flow) Phase 0 runs the toolchain preflight after profile resolution; it prompts **only** when a required tool is missing, and Cancel is the recommended option
- (docs flow) Every gate in the `gate-ledger.md` registry appends its row **when the gate completes**; a missing row, an unconverted `UNAVAILABLE`, or an unattributed skip is a `doc-reviewer` BLOCKER
- A phase's `choices:` array is presented verbatim — order, wording, and the `(Recommended)` marker are not the orchestrator's to change

Key invariants for `/release-notes`:

- **Zero direct API calls** — PR URLs are identifiers only; the agent never calls a REST API directly over HTTPS. Opt-in diff grounding reuses `diff-summarizer` (GitHub may use the `gh` CLI, which wraps the API — allowed; Bitbucket is pure local `git`); all resolution runs against clones under `$REPOS_PATH`
- `jira-reader` is read-only
- The draft is the **authored body only** — for a titled destination a `{{#context}}` label, `### title`, and customer-facing prose; for `fixes` ONE bare past-tense sentence. NEVER a Jira ID/key, a PR link, a `Change type:` line, or a `{{#internal-note}}` block (the docs automation adds the metadata wrapper)
- The `{{#context}}` label IS the imported `release_notes_category`, used verbatim; absent ⇒ the line is omitted. Change Type is sourced `imported_change_type` → infer, drives destination + shape only, and is confirmed with the user only on a low-confidence inference — by shape and destination, never by enum label
- The Summary is shaped per its destination (breaking → present tense, what breaks, remediation; feature update → benefit-led, plus a docs/blog link on a dev-phase run only; fixes → one past-tense sentence, no hedging, no internal terms); exactly ONE Summary per run, and no title or prose names the release version
- The run is gated on the imported `relevant_for_release_notes` — an explicit `false` stops with `RELEASE_NOTES_NOT_RELEVANT` (overridable); absent proceeds silently
- A deprecation carries a deprecation note in the Summary — end-of-life date (required) + end-of-support date (optional); a missing required date becomes a `deprecation_eol` gap the command asks about (never invented)
- NEVER writes into a docs repo; the default destination is persistent (never `/tmp`)
- Light gate only — `dt-style-checker` (optional, skipped if `dt-style-guide` absent); no Opus review, no tests, no branch (`specs-preflight` switches `$SPECS_PATH` only between branches that already exist, and only plugin-created ones — `references/specs-repo-git.md` §2.2; it creates none), and no commit of the draft or of anything in a docs/code repo, the vault, or the current working directory. The terminal `commit-artifacts` step still runs, committing ONLY `$SPECS_PATH`'s bounded session-artifact paths (`references/specs-repo-git.md` §2.1)
- Diff grounding is opt-in; when on, it reuses `$REPOS_PATH` resolution + `diff-summarizer`

Key invariants for the VI-creation flow (`/idea`, `/create-vi`, `/create-ard`, `/specify`, `/design`, `/ready`):

- Each authoring command is gated by its own Opus reviewer (`vi-reviewer`, `ard-reviewer`, `spec-reviewer`, `design-reviewer`; `/ready` by `readiness-reviewer`); `/idea` has no reviewer — its bounded grill is the gate
- Only `/idea`'s embedded grill is **bounded** (≤5 questions; `--deep` switches it to relentless), with leftover gaps becoming capped `[NEEDS CLARIFICATION]` markers + logged assumptions; `/create-vi`, `/create-ard`, `/specify`, and `/design` (and `/update-vi`) grill **relentlessly** to convergence with no cap (`references/grilling-technique.md`)
- VI / ARD / `specification.md` / `design.md` are written under `$SPECS_PATH/specifications/<KEY>-<slug>/`; `/idea` writes `idea.md` under `$VAULT_PATH` (pre-VI-Key)
- `/create-ard` grounds on mounted repos it discovers (`$REPOS_PATH` listing + theme→repo proposal + confirm/mount-or-descope); it never reads PRs
- `/ready` is **read-only** — it verifies the Jira status against the ARD/spec/design, never sets status, and never commits the deliverable or the `_readiness.md` snapshot (its terminal `commit-artifacts` step commits ONLY `$SPECS_PATH`'s bounded session-artifact paths, `references/specs-repo-git.md` §2.1)
- `/design`, `/implement`, `/specify`, `/epics`, `/ready` respect the applicable ARD via `references/ard-resolution.md`; an `AD-N` Rule violated without a recorded "ARD deviation" is a reviewer BLOCKER
- `/create-vi` does NOT capture `release_versions` / `change_type` / `release_notes_category` — they are Jira-mirror fields per `references/vi-format.md`, set as Jira dropdowns and returned by the importer; `vi-reviewer` neither requires nor validates them
- `/idea` types a Jira source from the export's `issue_type` (`ValueIncrement` → `vi`, `Product Need` → `rfe`), never from the project prefix, and resolves it with `resolve-export-for-key` at any depth; a `vi` source is prior art recorded in **both** `sources:` and `## Prior art`
- `/idea` Phase 4 derives its write path from the container rule and gates only when a rewrite target or a high-confidence area proposal exists; the resulting `vi_disposition` decides whether Phase 5 tells the user to create a Jira workitem

Key invariants for `$DOCS_PATH` docs grounding:

- Read-only; never writes into `$DOCS_PATH`; advisory only — never a gate or reviewer BLOCKER
- Default ON when `$DOCS_PATH` (`:-/workspace/docs`) is a readable dir with ≥1 markdown file; `--no-docs` off, `--docs <path>` override; every miss is a silent non-blocking skip
- Grill commands rank challenges into the Impact × Uncertainty gap list (never append — preserves `/idea`'s ≤5 bound); writer commands attach the digest
- `docs-grounder` retrieves via `qmd` CLI (no skill installed) but only ever **probes** the index — it never builds or refreshes one; index building and refreshing happen only in `resolve-docs-grounding` step 3.5, gated on user consent — with keyword + `git log --grep` fallback; write roots `SPECS_PATH`/`VAULT_PATH` stay strict (no default)

Key invariants for specs-repo git (`references/specs-repo-git.md`):

- Every git invocation is `git -C "$SPECS_PATH"` — the working directory is NEVER changed; nine of the seventeen callers are standing in a different repository
- Staging is by enumeration over `git status --porcelain --untracked-files=all`, never by glob; `git add -A` is only ever issued as `git add -A -- <literal paths>`, and `-A` is required because cost reconciliation deletes a pending file
- Only `^(vi|ard|spec|design)/` branches are the plugin's to switch away from or delete; any other **named** branch is left alone and the artifacts are committed on it
- **Detached HEAD is the one blocking state** — it sets `specs_git: blocked` for the whole run, `commit-artifacts` skips on that flag, and the notice fires at both ends. A dirty unrelated path (G1) does NOT block the terminal commit
- Never force-push, never `branch -D`, never merge/rebase/reset, never delete an `index.lock`, never open a PR, never call a REST API
- Never fatal — every failure is reported and the run continues
- The artifact commit carries no `Co-Authored-By` trailer; each artifact already carries its own `author:` field
- The canonical terminal order is deliverable + handoff → feedback → follow-ups → cost → `resume.md` → `commit-artifacts` → the run's last printed output. The one exception is a phase that cedes control (`/prompt-brainstorm`'s hand-off to `superpowers:brainstorming`, `/prompt-grill-me`'s long interactive grill): there `commit-artifacts` runs immediately **before** the hand-off, because a commit placed after it would never execute (`references/specs-repo-git.md` §4)
- Exactly one `Specs repo:` outcome line per run, wherever `commit-artifacts` ran — at the end, or immediately before a hand-off that cedes control (`/prompt-brainstorm`, `/prompt-grill-me`); a guard notice is repeated in full there, never only at the preflight

## Test-writing requirement for code changes

Any `/implement` invocation that touches source code **must**
produce at least one passing test for each new or changed behaviour before the
workflow is considered complete.

- Prefer unit tests; use integration or end-to-end tests only if that is the project's established pattern
- Tests must be meaningful (assert specific behaviour), deterministic, and follow existing project conventions
- If no test framework is detected, the workflow surfaces this explicitly — it never silently skips test-writing
- Docs-only changes (`/document`) are exempt from this requirement

## Updating installed plugins after editing

After editing files in this repo and pushing, reinstall the affected plugin on
each machine so Claude Code picks up the new command, agent, hook, and
reference content:

```bash
claude plugin reinstall dev-workflows@ihudak-plugins
```

Use the same pattern for any other plugin in this marketplace.

## Behavioral guardrails (Karpathy) — marketplace-specific notes

These notes complement the user-scope Claude guidance. They add only the
marketplace-specific behaviors that are easy to forget during workflow edits.

- **Goal-Driven Execution** maps directly onto the existing `test-baseliner` → implementation → `test-writer` → re-run flow enforced by `dev-workflows`. Frame each command invocation as a verifiable goal up front so the test gates have a concrete target to check.
- **Surgical Changes** applies in both directions when you edit command docs, agent prompts, hook declarations, or `references/model-routing/classification.md`: if you remove a `model_routing` field, phase, or workflow edge, remove every cross-reference to it in the same change. Stale references between commands and agents silently break the workflow.

## Git

- `origin` → `git@github-ig.com:ihudak/ihudak-claude-plugins.git`
- Default branch: `main`

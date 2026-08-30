# References reference

`dev-workflows` bundles 106 files under `references/` — 44 top-level markdown files, `cost-prices.yaml`, one file under `model-routing/`, and six bundled subtrees. This page enumerates every file a command or agent actually cites by name (46 of the 106 — the 44 top-level files plus `cost-prices.yaml` plus `model-routing/classification.md`), grouped by concern below, then counts the six subtrees rather than listing each file inside them. The arithmetic: 44 + 1 + 1 = 46 named individually, plus 24 + 11 + 10 + 5 + 3 + 2 = 55 markdown pages counted (not enumerated) across the six subtrees — 46 + 55 = 101 accounted for, against 106 files on disk. The remaining five are non-markdown data or templates inside those same subtrees, deliberately not listed as reference pages: `api-guidelines/template/openapi-template.yaml`, `api-guidelines/spectral/ruleset.yaml`, `docs-profiles/docs-profile.default.yml`, `docs-profiles/default-owners.txt`, and `guidelines/check_guidelines.py` — a template, a Spectral ruleset, a defaults file, an owners list, and a lint script, none of them prose a reader would open. The 55-file subtree figures below are markdown-page counts specifically; the five files above already sit inside those same subtrees and are not part of that count, so nobody should later "correct" a subtree figure by adding them back in.

## Authoring formats

The canonical structure each artifact type is authored and reviewed against, plus the shared conventions every authoring command applies while writing one.

- `brd-addressing.md` — the key grammar and the depth-bounded folder-resolution rule for a BRD (business requirements document) at any nesting level under `specifications/`, bounded by the key's own segment count so a slice of a slice still resolves; `/brd-intake`, `/brd-ground`, and `/brd-split` each cite it for key validation and BRD-folder resolution.
- `brd-format.md` — what a BRD is (customer-supplied, immutable once intaken, markdown only), the `[BR#n]` inventory row shape and the split-on-multiple-obligations rule, the six `[DEF#n]` defect classes, and defect-resolution states; `/brd-intake` authors against it and `brd-reader` extracts against it, while `/brd-ground` and `/brd-split` read its defect classes and resolution states.
- `bundle-packaging.md` — how the customer-facing bundle is built plugin-free (D12): the four rules that keep it followable by a reviewer with nothing installed, including locating documents by filename search rather than by path; the de-Obsidianising pass that rewrites wikilinks to plain filename references and keeps callouts; the three degradation tiers and what each obliges a returned review to state about its own evidence; the delivery note's 200-word ceiling and the two facts it must carry; and the committed `bundle-<YYYYMMDD>/` directory (D18) that is the permanent record of what was sent. Nothing consumes it yet — `/brd-package` will build against it and `/brd-reconcile` will read a review returned against one, once they exist.
- `coverage-ledger-format.md` — the coverage ledger's row shape, its six dispositions (only `unallocated` blocks), the allocation gate `/brd-split` enforces, and the PRD-eligibility rule read from it; `/brd-intake` writes the ledger against it, and `/brd-ground` and `/brd-split` read and update it.
- `customer-review-schema.md` — the twelve sections the customer's reviewer fills and sends back, the rule that puts the review's evidence limitations ahead of every claim resting on them, and the D13 rule that the review is exactly one new file with nothing in the package modified; unlike every other reference here its body is rendered verbatim into the customer's prompt, so it names no path, command, agent or skill a reader with nothing installed could not resolve. Nothing consumes it yet — `/brd-package` will inline it and `/brd-reconcile` will parse a returned review against it, once they exist.
- `decision-register-format.md` — the decision register's record shape for a `[VD#n]` (delivery-team) and `[CD#n]` (customer) decision, its five statuses (including the first-class `withdrawn`), the mandatory `argumentation` field, the two causes that may reopen a decision, what `conditional_on` records and makes findable, the D19 rule against resting solely on a `will-change` finding, and the `[AS#n]` assumption every open one of which reaches the customer; `/brd-interview` writes `[VD#n]` and `[AS#n]` records against it and enforces its will-change rule, and `brd-package-reviewer` reads them, while `/brd-package` and `/brd-reconcile` will consume it once they exist.
- `grounding-format.md` — the grounding finding contract: the `[CG#n]`/`[DG#n]` record shape, the six verdicts, the `baseline-integrity` procedure, the `current`/`will-change` horizons, the four design-grounding reconciliation classes, the optional derivation matrix, and the four verification outcomes; `/brd-ground` authors against it through `code-grounder`, `design-grounder`, and `grounding-verifier`, and `/brd-split` reads its recorded verdicts.
- `interview-tagging.md` — the interview's three question tags (`[G]` answered from grounding by nobody, `[V]` decided by the delivery team with argumentation, `[C]` put to the customer via the review package), the rule each tag fixes about who may answer, the re-tagging of a `[G]` grounding cannot settle, the split of a question carrying two tags, and the rule that closes a round; `/brd-interview` tags every question against it and `brd-package-reviewer` applies its test to one already routed, while `/brd-package` will consume it once it exists.
- `idea-format.md` — canonical structure and per-section rules for a refined idea brief; `/idea` is the only author and cites it directly, while `/create-prd` consumes the resulting artifact without citing this format doc.
- `prd-format.md` — canonical structure and per-section rules for a Product Requirements Document file; `/create-prd` and `/update-prd` author against it, `prd-reviewer` reviews against it, and `/release-notes` reads its Jira-mirror fields.
- `prd-source-resolution.md` — the Jira-import-first resolution ladder for an existing Product Requirements Document: once a PRD has been pasted into Jira and gained comments, Jira — not the specs-repo markdown — is authoritative.
- `ard-format.md` — canonical structure and rules for an Architecture Requirements/Decision Document; `ard-reviewer` reviews against it and `/ready` reads its `grounded_repos:` frontmatter.
- `specification-format.md` — canonical structure and per-stage rules for a product specification; `/specify` authors against it and `spec-reviewer` reviews against it. An embedded snapshot, not a net-new format.
- `design-format.md` — canonical structure and per-section rules for an engineering design; `/design` authors against it, `design-reviewer` reviews against it, `interface-designer` reads its `## Seams` categories, and `/ready` reads its repos header.
- `grilling-technique.md` — the one-question-at-a-time interview technique every authoring command (and `/prompt-grill-me`) uses to refine an artifact; embedded so callers carry no runtime dependency.
- `prose-formatting.md` — the line-wrapping rule every authoring command and agent applies: never hard-wrap prose, write each paragraph or prose block as one unbroken line.
- `release-note-types.md` — the release-note destination map (breaking-changes / feature-updates / fixes), the per-destination draft shape and prose rules, and the deprecation-note rule; consulted by `release-notes-writer`.
- `doc-structure-conventions.md` — three product-docs authoring conventions: the traceability boundary, callout scope and adjacency, and component-pattern fidelity; consumed by `/document`, `/epics`, `doc-planner`, `doc-writer`, and `doc-reviewer`.

## Git and handoff

The two git entry points that bound every write into the specs repo, plus the naming and read-only-mount conventions those entry points depend on.

- `specs-repo-git.md` — the two git entry points every bookkeeping write against the specs repo runs through: a start-of-run preflight and a terminal artifact commit, both bounded to plugin-created branches and enumerated paths, never fatal.
- `phase-handoff.md` — the two phase-boundary git entry points: a producer step that lands a phase's deliverable on the specs repo's default branch, and a consumer gate that requires the deliverable be there before expensive work starts.
- `branch-naming.md` — how the five commands that branch in a code repo (`/implement`, `/document`, `/docs-profile`, `/upgrade`, `/vuln`) decide a branch name; the specs-repo handoff branches are named by `phase-handoff.md` §2.2 instead: the target repo's own documented convention always wins, and this doc supplies one only when the repo documents none.
- `finish-and-handoff.md` — the mechanics `/document` (Jira mode) uses for its inline-profiling-branch handling and its finish-and-handoff step: squash, opt-in push, copy-paste PR draft.
- `read-only-repos.md` — how to detect a read-only repository mount, what to skip when one is found, and how to resolve a ref and read from it without ever attempting a write.

## Review and triage

The gates a written artifact passes through before it counts as done, and the discipline for turning a reviewer's findings into fixes.

- `finding-triage.md` — the step between a reviewer's findings and a fixer's edits: verify each finding at the location it names, record every dismissal with a reason, and hand the fixer survivors only.
- `gate-ledger.md` — the six verification-gate outcomes and the rule that no outcome is orchestrator-assignable to mean "I decided not to run this"; consumed by `/document` and the agents whose gates it registers.
- `repo-verification-gates.md` — how to extract a docs repo's own pre-PR checklist into a structured block a reviewer can check the written files against, augmenting the plugin's own gates rather than overriding them.
- `pre-lint.md` — deterministic, grep-expressible structural checks a reviewer-gated command runs against a just-authored artifact before spending an Opus review pass on mechanical structure.
- `source-truth.md` — the Implementation-vs-Description discrepancy-escalation protocol: how to verify a user-visible claim against shipped source, and what to do when Jira and source disagree.
- `escalation-rules.md` — the canonical `choices:` arrays for escalation decision points, so every stop-and-ask prompt across the plugin offers consistently-shaped options.
- `workflow-states.md` — maps each Jira workflow status on the PRD and Epic ladders to its owning role, the command that drives the transition into it, and the artifacts expected to exist at that status; the rubric `readiness-reviewer` applies.
- `ard-resolution.md` — given a Jira item, resolves any applicable ARD(s) into a normalized context (or `none`); cited by every command that must honor an ARD's invariants as implementation guardrails.
- `bug-diagnosis.md` — the bug-diagnosis discipline `/implement` follows for a bug-shaped task: a deterministic repro before hypothesizing, ranked falsifiable hypotheses, tagged and cleaned-up instrumentation, a regression test at a correct seam.

## Grounding

Read-only, advisory context-gathering — never a gate, never a write into the source it reads.

- `docs-grounding.md` — the resolution gate, retrieval procedure, and consumption modes for optional `$DOCS_PATH` documentation grounding; read-only and advisory, never a gate or reviewer BLOCKER.
- `vault-prior-art.md` — how vault prior-art discovery works for the idea-authoring commands: supplied vs. discovered, the status-resolution ladder, and the container derivation a write-path default shares with it.
- `jira-input-resolution.md` — shared input-resolution mechanics for the Jira-driven commands, including the `resolve-export-for-key` sub-procedure `/idea` also uses on its own.

## Session artifacts

The bookkeeping every long-running command emits around its actual work — cost, feedback, follow-ups, hygiene, and the maintenance loop that feeds tooling improvements back in.

- `cost-emission.md` — the session-cost subsystem every PRD-lifecycle command's terminal "Session cost" phase cites: how a run's dollar cost is computed, attributed, and persisted.
- `feedback-emission.md` — the session-feedback emitter the thirteen workflow commands' automatic maintenance phase (and `/feedback`/`/prompt*`) cites to capture friction about the plugin itself.
- `followup-emission.md` — the follow-up task and journal emitter a terminal "Emit follow-up tasks" phase cites in `/document`, `/release-notes`, `/epics`, `/implement`, and `/ready`.
- `next-phase-offer.md` — the plugin-wide contract for the next-phase offer every pipeline command surfaces at the end of its run, naming the natural next command(s).
- `session-hygiene.md` — the plugin-wide contract for session-hygiene suggestions: flush resume-critical state to disk, then suggest the right context action, after a big command finishes or a long run checkpoints.
- `context-management.md` — strategies for an implementation run whose step list is too long to complete in one context window without degrading.
- `instruction-file-maintenance.md` — the verification discipline for changes to agent-instruction files: verify every command claim against what actually runs it, itemise a narrowed rule as a deletion, and never retire a rule on "it looks derivable."

## Environment

What the plugin needs installed or configured around it, independent of any single artifact or command.

- `dependencies.md` — how dev-workflows relates to companion plugins with no hard dependency: convention plus runtime-resolve plus graceful fallback, since Claude Code plugins express no dependency-manifest field.
- `toolchain-preflight.md` — the Phase 0 environment check `/document` runs: deriving the required tool set from the resolved profile and the repo's own documented prerequisites, prompting only on a missing tool.
- `cost-prices.yaml` — the default per-model token-price table session-cost reporting prices against; user-overridable via `$DEV_WORKFLOWS_COST_PRICES` or a repo-local file of the same shape.
- `classification.md` — lives under `model-routing/`, not the top level; the single source of truth for task-complexity classification, the model fallback chain, the mandatory Opus code-review checklist, and the `model_routing` handoff block every pipeline command loads at its own classification step.

## Bundled reference sets

Six subtrees carry bundled guidance too large or too domain-specific to enumerate file-by-file; each is counted here instead.

- `api-guidelines/` (24) — REST API and IAM permission-naming guidance distilled from public sources (Google AIP, Zalando, Microsoft, OpenAPI 3.1, RFCs), consulted by `/api-guideline-reviewer`; also carries `spectral/ruleset.yaml`, the executable Spectral ruleset that command lints with when a Spectral CLI is available.
- `guidelines/` (11) — UI design-system and accessibility rules distilled from public standards (Apple HIG, Material Design, Fluent, W3C WCAG/ARIA), consulted by `/guideline-reviewer`.
- `handoff/` (10) — one input/output document-format contract per agent, usually read by the agent itself rather than by the dispatching command — `handoff/test-baseliner.md` is the exception, read by `vuln-fixer` and `upgrade-executor`, which dispatch it.
- `docs-profiles/` (5) — docs-profile authoring conventions for the built-in `example-docs` worked example (frontmatter, changelog, anchors, render verification, the docs-profile schema), consulted by `/docs-profile`, `/document`, and the `docs-frontmatter` skill.
- `upgrade/` (3) — component-specific upgrade guidance, consulted by `upgrade-planner` and `upgrade-executor`.
- `fix-vuln/` (2) — CVE-remediation guidance, consulted by `vuln-research` and `vuln-fixer`.

Three of these subtrees (`api-guidelines/`, `guidelines/`, `docs-profiles/`) also hold the data or template files named in the introduction above, so their `*.md` count here is smaller than `find <dir> -type f` would report; `handoff/`, `upgrade/`, and `fix-vuln/` are markdown only, and for those the two counts agree.

## Skills

Two skills ship under `skills/` — reusable guidance packaged for the `Skill` tool, distinct from a `references/` file that a command or agent reads directly by path.

| Skill | Invocable | What it's for |
|---|---|---|
| `model-routing` | No — loaded internally, at the classification step, by the 14 pipeline commands whose slash-command bodies cannot expand `${CLAUDE_PLUGIN_ROOT}` themselves | Resolves `references/model-routing/classification.md` and hands the caller the task-complexity classification rules and the model fallback chain. |
| `docs-frontmatter` | Yes | Applies documentation frontmatter conventions — changelog entries, page owners, core metadata fields — when editing a page under any content root the applicable docs profile declares. |

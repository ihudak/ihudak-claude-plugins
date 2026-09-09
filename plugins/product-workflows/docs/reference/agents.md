# Agents reference

`product-workflows` bundles 13 reusable subagents under `agents/`, dispatched internally by the invoking command via `subagent_type: "product-workflows:<name>"` — none of them is a user entry point. Nine carry a `model: opus` frontmatter pin (shown as **opus** below) and run on Opus every time, regardless of the dispatching command's own model tier for that run; one, `brd-reader`, carries a `model: sonnet` frontmatter pin (shown as **sonnet** below) and runs on Sonnet every time, because its extraction work is mechanical; the remaining three carry no pin (shown as **per routing**) and are assigned a tier by the dispatching command per the task-complexity classification in `workflows-core`'s model-routing classification reference. Three further agents this plugin's commands dispatch — `workflows-core:code-scanner`, `workflows-core:docs-grounder`, and `workflows-core:impl-maintenance` — ship in the companion `workflows-core` plugin and are listed in its own agents reference, not here. Agents are grouped below by role — reviewers and planners, readers and scanners, and writers — and each row's **Used by** column lists only the commands that actually dispatch that agent as a subagent.

## Reviewers and planners

Opus-gated quality gates, plus the one Sonnet-tier verifier that re-derives evidence rather than judging it.

| Agent | Model | Tools | What it does | Used by |
|---|---|---|---|---|
| `ard-reviewer` | opus | Read, Glob, Grep, Skill | Reviews an ARD for grounding integrity, well-formed `AD#N` rules, non-contradiction with inherited PRD-level invariants, and altitude purity; returns PASS / PASS WITH RECOMMENDATIONS / BLOCK. | `/create-ard` |
| `brd-package-reviewer` | opus | Read, Glob, Grep, Skill | Attacks a BRD package before it reaches the customer — unsupported decisions, a `[C]` that is really a `[V]`, assumptions as facts, overclaims, a defect claim nothing holds; returns `[SR#n]`. | `/brd-package` |
| `epic-reviewer` | opus | Read, Glob, Grep | Reviews Epic drafts for goal clarity, testable acceptance criteria, scope boundaries, and non-duplication with existing Epics under the parent PRD. | `/epics` |
| `grounding-verifier` | opus | Read, Glob, Grep, Bash, Skill | Re-derives a `[CG#n]`/`[DG#n]` from its source — the pinned repo, or the frame set for a design-only one — without first reading `evidence`; returns agree / extend / contradict / unprovable. | `/prd-ground` |
| `prd-reviewer` | opus | Read, Glob, Grep, Skill | Reviews a Product Requirements Document for goal crispness, testable stories/criteria, internal consistency, measurable metrics, and product-level purity (no implementation detail). | `/create-prd`, `/update-prd` |
| `proposal-reviewer` | opus | Read, Glob, Grep, Skill | Attacks an effort proposal before a customer sees it — re-adds the hours, resolves driver citations, checks the tier and brief against the evidence; returns PASS / PASS WITH RECOMMENDATIONS / BLOCK. | `/prd-proposal`, `/brd-proposal` |
| `spec-reviewer` | opus | Read, Glob, Grep | Reviews a specification for per-stage quality, cross-stage consistency, coverage, and identifier integrity. | `/specify` |

## Readers and scanners

Read-only discovery and grounding — each returns a structured digest rather than editing anything.

| Agent | Model | Tools | What it does | Used by |
|---|---|---|---|---|
| `brd-reader` | sonnet | Read, Glob, Grep | Extracts a `[BR#n]` inventory from a BRD — `source_anchor` per row, unconfirmed `defect_candidates`, multi-obligation requirements split, every heading yielding no row accounted for. Read-only. | `/brd-intake` |
| `code-grounder` | opus | Read, Glob, Grep, Bash, Skill | Grounds specific BRD claims against one repository at a pinned commit — one `[CG#n]` finding per claim, verifying `HEAD` matches the pin before grounding anything. | `/prd-ground` |
| `customer-review-reader` | per routing | Read, Glob, Grep | Reads a returned customer review in two modes — parses a schema-shaped file, or drafts that schema from prose; every free-text inference returns an unconfirmed candidate. | `/brd-reconcile` |
| `design-grounder` | opus | Read, Glob, Grep, Skill | Reconciles a BRD against an exported design frame set — one `[DG#n]` per divergence in four classes; refuses without an index file; the code-capture class cites a `[CG#n]` instead of asserting it. | `/prd-ground` |
| `idea-reader` | per routing | Read, Glob, Grep, Skill | Ingests one idea source into a source digest for `/idea`: links two levels deep in either syntax, linked images read and described as context, every other linked file enumerated but never opened. | `/idea` |

## Writers

Produce artifact content from a structured handoff. Does not run git.

| Agent | Model | Tools | What it does | Used by |
|---|---|---|---|---|
| `epic-writer` | per routing | Read, Glob, Grep, Write, Edit, Skill | Writes one file per child Epic from a structured handoff, traceable to the PRD it partitions and `code-scanner` evidence; write-only, never commits. | `/epics` |

Every one of the 13 agents above is dispatched by at least one command. There is no maintenance section here: `workflows-core:impl-maintenance`, dispatched by all 14 commands, ships in `workflows-core`. `workflows-core:docs-grounder` is the one agent no command here dispatches by writing a `subagent_type:` inline — its callers invoke a named procedure defined in its own governing reference file instead.

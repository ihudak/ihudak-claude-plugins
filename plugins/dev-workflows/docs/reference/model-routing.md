# Model routing reference

Every pipeline command classifies its own task before doing real work, and that classification decides how much planning, authoring, and review rigor the rest of the run applies — and, for two commands, which model the session itself must be running on. This page covers the four things a user can observe or influence about that; the full policy — including the mechanics agents don't need restated here — lives in `classification.md` and is linked at the end.

## What gets classified

| Class | Plain meaning |
|---|---|
| `SIMPLE` | Trivial, mechanical, low blast radius — a typo, a comment, a single-line tweak. |
| `MODERATE` | A localized feature or fix in 1–3 files, well-understood, no security implications. |
| `SIGNIFICANT` | Multi-file or cross-cutting, non-trivial design, real correctness risk. |
| `HIGH-RISK` | Security-, data-, or contract-sensitive — a mistake here causes an outage or a breach. |

All twenty-one pipeline commands that load the `model-routing` skill run this classification as an early step and state their class plus a one-line reason: `/implement`, `/document`, `/epics`, `/release-notes`, `/vuln`, `/upgrade`, `/docs-profile`, `/idea`, `/create-prd`, `/update-prd`, `/create-ard`, `/specify`, `/design`, `/ready`, `/frames`, and the six commands of the BRD-to-PRD route — `/brd-intake`, `/brd-ground`, `/brd-split`, `/brd-interview`, `/brd-package` and `/brd-reconcile`. Each command has a typical class for its own kind of work (a Product Requirements Document authoring run is typically `MODERATE`, keyed feature docs are typically `SIGNIFICANT`) but escalates when the task in front of it warrants it. What over-escalating costs differs by command — from an extra Opus planner call to a hard stop requiring an Opus session (`## What classification changes` below has the breakdown) — while misclassifying downward can ship bugs regardless of which command you're running, so the policy's own rule is to escalate one level whenever in doubt.

## What classification changes

`SIMPLE` and `MODERATE` continue on whatever model the session is already running, with nothing extra added on their account.

`SIGNIFICANT` and `HIGH-RISK` change different things depending on which command you're running, because three distinct patterns share this classification:

- **`/implement` and `/upgrade`** delegate planning (or a planning critique) to a dedicated Opus sub-agent (`risk-planner`) before implementation starts, then add a separate Opus `code-review` gate afterward, before tests run; at `SIMPLE`/`MODERATE` neither one is dispatched at all.
- **The reviewer-gated authoring and documentation commands** — `/create-prd`, `/create-ard`, `/specify`, `/design`, `/document`, `/epics`, and `/ready` among them — already run their own reviewer agent on Opus by a fixed frontmatter pin, regardless of classification — with one exception: `/document`'s direct mode runs no reviewer at all, and is deliberately gated by a style check alone. Apart from `/document`, which dispatches the delegated planner `doc-planner`, there is no separate delegated planner sub-agent in this pattern. What classification changes here is grill depth and authoring rigor, not whether the review runs on Opus — [Agents reference](agents.md) carries the complete list of which agents are pinned and which commands dispatch them.
- **`/vuln`** is a third: it runs the same Opus `code-review` gate, triage, and `review-fixer` cycle at `SIGNIFICANT`/`HIGH-RISK`, but dispatches no `risk-planner` and has no frontmatter-pinned authoring reviewer of its own.
- **`/design` and `/create-ard` add a further, stricter gate:** at `SIGNIFICANT`/`HIGH-RISK` neither will author against a weaker model — `/design` requires the session itself to already be running on an Opus-tier model, while `/create-ard` gates on whether an Opus tier is reachable at all, because their authoring happens inline rather than through a delegated sub-agent. If it isn't, the run stops and offers to relaunch on Opus, with an explicit override to proceed anyway that gets logged in the final report. `/specify` and `/create-prd` don't gate this way on the same classification — they degrade to the best available model and record the degradation instead of stopping.

## What floors a classification

`/implement` has one classification floor beyond the ordinary triggers: **multi-source input**. Handing it more than one code repository, or any directory input (a saved file folder, or a spec/design folder), floors the run at `SIGNIFICANT` even if nothing else about the change looks that size — a large multi-source brief is cross-cutting by nature, and it also triggers a parallel per-repo scan fan-out documented in the full policy below. The floor is overridable at plan approval if you judge the work genuinely smaller than its input footprint suggests.

## The fallback chain

Every `SIGNIFICANT`/`HIGH-RISK` Opus step resolves against the same ordered list, taking the first model available in the environment:

1. `claude-opus-5`
2. `claude-opus-4-8`
3. `claude-opus-4-7`
4. `claude-opus-4-6`
5. `claude-sonnet-5` (fallback only — the report notes that no Opus was available)
6. `claude-sonnet-4-6` (further fallback)
7. `claude-sonnet-4-5` (further fallback — the report notes "no Opus or Sonnet 5/4.6 available")

`claude-sonnet-4-5` is the floor. If nothing in the list is available, the run stops and asks how to proceed rather than silently downgrading. You never pick a model for any of this yourself — the orchestrator resolves the chain automatically against what your environment has available, and every downgrade from the top of the chain is announced in the run's own report rather than happening quietly.

---

The full policy — the classification triggers in detail, the `model_routing` handoff block, the mid-tier detection chain used for mechanical steps, the mandatory Opus code-review checklist, and the large-input scan fan-out — is authoritative in [`../../references/model-routing/classification.md`](../../references/model-routing/classification.md). This page is a summary of it, not a substitute for it.

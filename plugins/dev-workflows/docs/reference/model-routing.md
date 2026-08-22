# Model routing reference

Every pipeline command classifies its own task before doing real work, and that classification decides whether an Opus planner and an Opus review gate join the run. This page covers the four things a user can observe or influence about that; the full policy — including the mechanics agents don't need restated here — lives in `classification.md` and is linked at the end.

## What gets classified

| Class | Plain meaning |
|---|---|
| `SIMPLE` | Trivial, mechanical, low blast radius — a typo, a comment, a single-line tweak. |
| `MODERATE` | A localized feature or fix in 1–3 files, well-understood, no security implications. |
| `SIGNIFICANT` | Multi-file or cross-cutting, non-trivial design, real correctness risk. |
| `HIGH-RISK` | Security-, data-, or contract-sensitive — a mistake here causes an outage or a breach. |

All fourteen pipeline commands that load the `model-routing` skill run this classification as an early step and state their class plus a one-line reason: `/implement`, `/document`, `/epics`, `/release-notes`, `/vuln`, `/upgrade`, `/docs-profile`, `/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/design`, and `/ready`. Each command has a typical class for its own kind of work (a Value Increment authoring run is typically `MODERATE`, Jira-driven feature docs are typically `SIGNIFICANT`) but escalates when the task in front of it warrants it — misclassifying upward costs one extra Opus call; misclassifying downward can ship bugs, so the policy's own rule is to escalate one level whenever in doubt.

## What classification changes

`SIMPLE` and `MODERATE` continue on whatever model the session is already running, with no extra Opus step added on their account.

`SIGNIFICANT` and `HIGH-RISK` add two mandatory steps: planning (or a planning critique) delegated to an Opus sub-agent before implementation starts, and a dedicated Opus code-review gate after implementation completes and before tests run. Several authoring commands' own reviewer agents already carry a fixed Opus pin in their frontmatter and run unconditionally, independent of this classification — [Agents reference](agents.md) has the complete list of which agents are pinned and which commands dispatch them. For those commands, what classification changes is the planner step, not whether the review itself runs on Opus.

## What floors a classification

`/implement` has one classification floor beyond the ordinary triggers: **multi-source input**. Handing it more than one code repository, or any directory input (an exported Jira ticket folder, or a spec/design folder), floors the run at `SIGNIFICANT` even if nothing else about the change looks that size — a large multi-source brief is cross-cutting by nature, and it also triggers a parallel per-repo scan fan-out documented in the full policy below. The floor is overridable at plan approval if you judge the work genuinely smaller than its input footprint suggests.

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

---
name: model-routing
description: Load the dev-workflows task-complexity classification rules and model fallback chain. Invoked at the classification step by the 14 pipeline commands (`/implement`, `/document`, `/epics`, `/release-notes`, `/vuln`, `/upgrade`, `/docs-profile`, `/idea`, `/create-prd`, `/update-prd`, `/create-ard`, `/specify`, `/design`, `/ready`), because slash-command bodies cannot expand ${CLAUDE_PLUGIN_ROOT} themselves.
user-invocable: false
allowed-tools: Read
---

# Model routing

Read the authoritative classification rules and model fallback chain:

`${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md`

Then classify the current task as exactly one of `SIMPLE`, `MODERATE`,
`SIGNIFICANT`, or `HIGH-RISK` using the criteria in that file, and apply the
model fallback chain and `model_routing` handoff block it defines. That file is
the single source of truth — do not paraphrase or cache its contents here.

# pm-workflows

A role-based pipeline of 12 slash commands for the product-definition side of the `dev-workflows` family. Its spine runs idea refinement → Product Requirements Document → architecture → Epic breakdown → specification, with an Opus-backed review gate behind every authored artifact; alongside it sits a six-command BRD-to-PRD route that grounds a customer's requirements document, settles it with them, and seeds the PRD, ARD and specification the ladder above hands off to. The table below is the complete list. The shared foundation every command here draws on — the addressing grammar, the git and phase-handoff entry points, model routing, escalation and triage, and the emitters — ships in the companion `workflows-core` plugin; the engineering half of the pipeline this hands off to — `/design`, `/implement`, `/ready` — ships in the companion `dev-workflows` plugin.

> Part of the `ihudak-plugins` marketplace — see the [repo-root setup guide](../../README.md) for marketplace install + prerequisites.

## What it does

| Role | Commands | What it does |
|------|----------|--------------|
| PM | `/idea`, `/create-prd`, `/update-prd` | Refine a raw idea, then author or refresh the Product Requirements Document. |
| PM *(BRD route — inventory)* | `/brd-intake`, `/brd-split` | Intake a customer BRD verbatim, extract its requirement inventory, and split it once every row has a recorded fate. |
| PM *(BRD route — customer loop)* | `/brd-interview`, `/brd-package`, `/brd-reconcile` | Decide the BRD's open questions, package what only the customer can settle, then reconcile the review that comes back and sweep what it overturned. |
| PA *(optional)* | `/create-ard`, `/brd-ground` | Ground an architecture decision, or a BRD's requirement claims, in the mounted implementation code. |
| PE | `/epics`, `/specify` | Break a PRD into Epics, then author an org-standard specification through a grill. |

Twelve agents (`ard-reviewer`, `brd-package-reviewer`, `brd-reader`, `code-grounder`, `customer-review-reader`, `design-grounder`, `epic-reviewer`, `epic-writer`, `grounding-verifier`, `idea-reader`, `prd-reviewer`, `spec-reviewer`) carry the BRD grounding and reconciliation, PRD/ARD/spec review, and Epic writing and review these commands share. Nine reference pages (`ard-format`, `brd-format`, `bundle-packaging`, `coverage-ledger-format`, `customer-review-schema`, `decision-register-format`, `idea-format`, `interview-tagging`, `specification-format`) define the BRD, decision-register, coverage-ledger, customer-review, idea, ARD and specification artifact formats.

A per-command and per-agent documentation tree (`docs/`) is not yet published for this plugin — this is an in-progress extraction from `dev-workflows`, and the tree lands in a later task of the same marketplace-split increment.

## Recommended environment

Mount every repository, your docs clone and your specs repo under one `/workspace`, matching this plugin's defaults, with [`ihudak/ai-containers`](https://github.com/ihudak/ai-containers). Outside a container the commands still work — set `$REPOS_PATH`, `$DOCS_PATH` and `$SPECS_PATH` yourself.

## License

MIT — see [LICENSE](LICENSE).

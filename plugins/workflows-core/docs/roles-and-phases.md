# Roles and phases

The `dev-workflows` plugin family charges every cost-emitting run to a `phase` and a `role`. Twelve phases exist, and the vocabulary itself belongs to the pipeline plugin whose commands own the lifecycle. This page says only what `workflows-core`'s own six commands do with it, because that is the part a reader of *these* commands needs.

## No command here owns a phase

None of the six commands in this plugin advances a product increment, so none of them mints a lifecycle phase of its own. Two mechanisms get them a label anyway:

- **Inheritance.** `/feedback`, `/prompt`, `/prompt-brainstorm` and `/prompt-grill-me` resolve the **target command** whose output they are correcting or remarking on, and take that command's own fixed `phase`/`role` pair. A `/prompt` correcting a `/specify` output is priced as `specification`/`pe`; one correcting a `/design` output as `planning`/`dev`. The cost of fixing a phase's output belongs to that phase.
- **Inference from the folder.** `/frames` reads the `kind` of the folder it resolved and charges accordingly — a BRD folder's frame set to `brd-to-prd`/`pm`, a PRD or Epic folder's to `prd-creation`/`pm`.

`/statusline` emits nothing at all: it sets a configuration value rather than running a task.

The three phases those two mechanisms can land on directly are described below. The other nine are reachable only by inheritance, and each is documented by the plugin whose command emits it.

### prd-creation

Role `pm`. Reached by `/frames` when the folder it resolved is a PRD or Epic folder, and by any of the four correction commands whose target command emits it. Being in this phase means the PRD does not yet have a merged specification or design — the work underway is idea refinement or PRD authoring.

### brd-to-prd

Role `pm`. Reached by `/frames` when the folder it resolved is a BRD folder, and by inheritance in the same way. Being in this phase means a customer-supplied BRD is somewhere on the BRD-to-PRD route — its inventory being extracted, grounded, split, decided, packaged, or reconciled.

### plugin-feedback

Role `n/a`. This is the fallback for `/feedback` and the three `/prompt*` commands, and no command reaches it by default: each first tries to inherit. It applies where no target command resolves, where the target has no attribution row of its own, or where the target is itself one of these four. Being in this phase means the run was about **the plugin itself** rather than the product, and no lifecycle phase owns it. `n/a` is the absence of a role recorded rather than guessed; aggregation should treat it as unattributed rather than folding it into `dev`.

---

**A second, unrelated `phase:` vocabulary exists in this family.** The model-routing resume phases — `full`, `verify-resume`, `regression-resume` — say how far a re-entered run must re-execute after a review or a failed test. They share nothing with the cost vocabulary but the field name. See [Session cost](reference/session-cost.md) for the mechanics of cost attribution itself.

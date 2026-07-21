# Documentation grounding on `$DOCS_PATH` (shared reference)

Several authoring commands produce markedly better output when grounded in the
product's existing shipped documentation — current behavior, customer-facing
terminology, and well-documented analogous features to model new work on. When
`$DOCS_PATH` is set and valid, the commands below ground on it automatically so
the operator never has to add "please also check the documentation in `<dir>`".

This governs *whether docs grounding runs and against what root*, and *how the
result is consumed*. It is **read-only**: these commands never write into
`$DOCS_PATH`. Every miss is a **silent, non-blocking skip** — never an error,
never `emit-block`.

Consumers: `/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/specify`
(grill-rank consumption); `/epics`, `/release-notes` (writer-attach consumption).
`/document` does **not** consume this file — it only uses `$DOCS_PATH` as a
write-target discovery hint (see its Phase 0).

## Procedure — `resolve-docs-grounding <command-name>`

1. **Flags first.** If the invocation carries `--no-docs`, return
   `docs_grounding: OFF`, `reason: "disabled with --no-docs"`. If it carries
   `--docs <path>`, set `docs_root = <path>` and skip step 2.
2. **Resolve the root.** `docs_root = ${DOCS_PATH:-/workspace/docs}` (a single
   directory; the AI container mounts docs at `/workspace/docs`, so the default
   lets grounding work even if the var is not re-exported).
3. **Validity gate — ON only when all hold** (else `OFF` with a one-line reason):
   - `docs_root` is non-empty,
   - it is an existing, readable directory (`test -d "$docs_root" && test -r "$docs_root"`),
   - it contains at least one markdown file
     (`find "$docs_root" -type f -name '*.md' -print -quit` is non-empty).
   On a host where `/workspace/docs` is absent, the gate fails → `OFF` → the run
   behaves exactly as it does today.
4. **Return** `{ docs_grounding, docs_root, reason }`.

**Default-safety note.** A `/workspace/*` default is safe here because this is a
read-only search base — a wrong/missing default just misses and silently skips.
This mirrors `${REPOS_PATH:-/workspace}`. Write roots (`SPECS_PATH`,
`VAULT_PATH`) deliberately do **not** default; do not change them.

## Plan-approval line

When `resolve-docs-grounding` returns, surface one line in the command's
plan/approval (or config-confirm) step, with an off switch:

```
docs grounding: ON  <docs_root>        (turn off with --no-docs)
docs grounding: OFF (<reason>)
```

## Dispatch — `dispatch-docs-grounder`

Run only when `docs_grounding: ON`. Dispatch the read-only agent (model tier per
the run's `model_routing` — the `detection_model` §2.1 Sonnet chain is the
default for this retrieval agent):

```
→ Agent (subagent_type: "dev-workflows:docs-grounder", model: <detection_model>):
  > "Ground this work in the product docs and return the digest:
  >
  > docs_path:       <docs_root>
  > feature_summary: <2–4 sentences: the goal + capability themes for this run>
  > jira_key:        <the VI/Epic/ticket key, or omit for keyless /idea>
  > themes:          [capability themes, or []]"
```

Wait for the digest. On `status: ERROR` or any dispatch failure, treat as
`docs_grounding: OFF` and proceed as today (record one line in the final report).
On `status: EMPTY`, proceed as today; the digest simply adds nothing.

## Consumption

**`grill-rank`** (`/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/specify`):
Feed `docs_references` to the grill as positive grounding (facts to build on,
analogous precedents to model after, building-block altitude/permissions).
**Rank** each `docs_challenges` entry into the command's existing
Impact × Uncertainty gap list — do **not** append. A docs challenge competes for
a question slot; it never adds one (this preserves `/idea`'s ≤5-question bound).

**`writer-attach`** (`/epics`, `/release-notes`): Pass the whole digest
(`docs_references` + `docs_challenges`) into the writer agent's input handoff as
`docs_grounding`. The writer uses references for consistency and treats
challenges as authoring cautions.

## Invariants

- Read-only; never writes into `$DOCS_PATH`.
- Never blocks; every failure is a silent, non-blocking skip.
- Advisory only — never a gate, never a reviewer BLOCKER.
- Single directory; `${DOCS_PATH:-/workspace/docs}`.

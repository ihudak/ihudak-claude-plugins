# ARD resolution (embedded — shared reference)

Given a Jira item, resolve any applicable **Architecture Requirements/Decision Document(s)** produced by
`/create-ard` and return a normalized **ARD context** — or **`none`**. Cited by `/design`, `/implement`,
`/specify`, and `/epics` so the resolution logic, the **optional/no-regression** rule, and the deviation-record
convention live in ONE place.

## Inputs

`vi` (VI key), `epic` (or `null`), `area` (or `null`), `$SPECS_PATH`.

## Resolution (most-specific first)

1. Resolve the VI dir `$SPECS_PATH/specifications/<VI>-<vslug>/` — match by key-number, tolerating a
   stray `-`/`_` and a human-adjusted slug (the same rule the other commands use).
2. Collect candidate ARD files:
   - **Epic-level** (`epic` set): `<VI>-<vslug>/<EPIC>-<eslug>/<EPIC>_ARD.md` and any
     `<EPIC>-<area>_ARD.md` (the area-scoped file when `area` is given, else every per-area ARD) **plus**
     the VI-level `<VI>-<vslug>/<VI>_ARD.md` for inherited invariants.
   - **VI-level** (`epic` null): only `<VI>-<vslug>/<VI>_ARD.md`.
3. Parse each file's `## Architecture decisions` into `AD-N {id, binds, prevents, rule, source}` where
   `source` ∈ `vi | epic | area`. VI-level `AD-N` are the inherited base; Epic/area `AD-N` layer on top
   (Epic/area wins on any conflict — contradictions were already blocked by `ard-reviewer` at authoring).

## Output — the ARD context, or `none`

```yaml
status: found | none
ard_paths: [ <absolute paths of the ARD files used> ]
invariants:
  - id: AD-1
    source: vi | epic | area
    binds: <text>
    prevents: <text>
    rule: <testable statement>
guidance_summary: <short prose: the ARD's non-AD-N architecture guidance the consumer should heed>
```

`status: none` when no ARD file resolves (the common case — `/create-ard` is optional).

## No-regression rule (central)

A caller that gets `status: none` **MUST behave exactly as it did before this feature** — no prompt, no
extra phase output, no reviewer dimension. The ARD steps are strictly additive and guarded on
`status: found`.

## Deviation-record convention

When an artifact must NOT honor an `AD-N`, the consumer records — in its **own** artifact, NEVER in the
ARD (role separation: the ARD is the architect's) — a line:

`- ARD deviation: [<AD-N id>] — <what deviates> — <why> — flag: architect`

and surfaces it in the run's final report. A reviewer treats a violating artifact **with** a matching
deviation record as *allowed-but-flagged* (the architect adjudicates), **without** one as a **BLOCKER**.

## Consumers (informative)

- `/design` — Epic-level ARD = design guidance; VI-level `AD-N` = inherited invariants; deviations → a `## ARD deviations` section in `design.md` + an open question.
- `/implement` — Jira mode only; `AD-N` = implementation guardrails; deviations → the Phase 5 report. Direct mode → `none`.
- `/specify` — keep user stories + scope consistent with `AD-N` + scope; deviations → the spec's `### Open questions`.
- `/epics` — VI-level only (`epic: null`, Epics do not exist yet); `AD-N` = inherited invariants the drafted Epics must respect; deviations → a `- ARD deviation: …` line in the Epic draft + the Phase 9 report.
- `/ready` — VI-level + Epic-level `AD-N` = inherited invariants passed to `readiness-reviewer` as `applicable_ard`; read-only — it never authors a deviation record, only checks the artifacts it reads for an existing one.

Each passes `invariants` to its reviewer as `applicable_ard`; the reviewer's ARD-conformance dimension is
skipped entirely when it is absent.

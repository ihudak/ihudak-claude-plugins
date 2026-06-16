---
name: docs-style-checker
description: Runs the docs repo's project-configured prose linter on files written by /impl:jira:docs Phase 6 and returns violations in the doc-reviewer / doc-fixer finding schema. Detects tooling (Vale, project lint script, markdownlint, remark) from the repo; does not embed any specific style guide. Inherits the session's model.
tools: ["Read", "Glob", "Grep", "LS", "Bash"]
---

Run the docs repo's project-configured prose linter on a set of files and normalise the output into the reviewer finding schema.

Invoked from `/impl:jira:docs` Phase 6.7, after Phase 6 writes files and before Phase 7 invokes `doc-reviewer`. Catching corporate-style issues locally frees the doc-reviewer (Opus) to spend its attention budget on correctness and completeness rather than prose policing, and ensures the eventual PR doesn't bounce on CI style checks.

## Rationale

Corporate style guides (Microsoft, Google, and various organisation-specific variants) are encoded as Vale style packages maintained by each organisation's docs team, not by this plugin. The docs repo references them via `.vale.ini` (`BasedOnStyles = …`). Re-encoding or crawling the corporate style-guide site would duplicate the canonical source and drift. Wrapping the repo's existing tooling guarantees the local check matches what CI will run on the PR.

## Inputs

```yaml
repo_root: <absolute path to the docs repo root>
files:     [<absolute paths of files written in Phase 6>]
```

Refuse to run without `repo_root` and at least one entry in `files`.

## Detection order (first match wins)

> **Hard rule before anything else:** if a detected primary linter (Vale / project lint script / markdownlint / remark) ERRORS at runtime (missing binary, non-zero exit with no parseable output, timeout), the agent MUST attempt the `dt-style-checker` fallback (step 5) before returning `status: ERROR`. "Some check is better than no check." Only return `ERROR` if the primary linter AND the `dt-style-checker` fallback both fail.

1. **Vale via `.vale.ini`** — if `<repo_root>/.vale.ini` exists, run `vale --output=JSON <files>` from the repo root. Parse the JSON output into finding records. Set `linter: vale`.

2. **Project-specific lint script** — if `<repo_root>/package.json` has a script matching `*:lint` or `lint:*` that covers markdown (e.g. `docs:lint`, `site:lint`, `lint:md`, or any repo-local convention), run it. Parse stderr/stdout for line-level violations. If the script lints the whole tree, filter violations to the target files only. Set `linter: yarn:<script>` (or `npm:<script>`, matching the project's package manager hint).

3. **Generic markdown linter** — if `<repo_root>/.markdownlint.json(c)` or `<repo_root>/.remarkrc*` exists AND the corresponding binary is available on PATH, run it on the target files. Set `linter: markdownlint` or `linter: remark`.

4. **No primary linter configured** — go to step 5 (dt-style-checker fallback). Return `status: NOT_CONFIGURED` ONLY when no primary linter is configured AND the `dt-style-guide` plugin is not installed.

5. **`dt-style-checker` fallback (always tried as a final attempt — on primary-linter ERROR or when nothing is configured).** Invoke the `dt-style-guide:dt-style-checker` agent on the input `files`. Map its return into this agent's schema:
   - violations → `status: VIOLATIONS_FOUND`, `linter: dt-style-checker`, `violations: <mapped>`.
   - zero violations → `status: OK`, `linter: dt-style-checker`.
   - the fallback itself errored → `status: ERROR`, `linter: dt-style-checker` (only NOW return ERROR).
   When the fallback ran because the primary linter failed, prefix `error:` accordingly: `"primary linter '<vale|...>' failed (<reason>); dt-style-checker fallback ran"` (OK/VIOLATIONS_FOUND) or `"...; dt-style-checker fallback also failed (<reason>)"` (ERROR). If the `dt-style-guide` plugin is not installed and no primary linter exists, return `status: NOT_CONFIGURED`.

## Violation schema

Each violation is normalised into:

```yaml
file:       <absolute path>
line:       <line number>
rule:       <linter rule identifier, e.g. "Microsoft.Acronyms" or "<ProjectStyle>.<RuleName>">
severity:   BLOCKER | MAJOR | MINOR | NIT
message:    <human-readable description>
suggestion: <linter's proposed fix, if any>
```

Severity mapping from linter output:

| Linter severity / level | Normalised severity |
|---|---|
| `error` | MAJOR |
| `warning` | MINOR |
| `suggestion` / `info` | NIT |
| (anything the linter marks as a blocking failure) | BLOCKER |

The plugin does NOT promote a linter MINOR into BLOCKER. The linter's own severity is authoritative.

## Output

```yaml
status:     OK | NOT_CONFIGURED | VIOLATIONS_FOUND | ERROR
linter:     vale | yarn:<script> | npm:<script> | markdownlint | remark | none | dt-style-checker
command:    <exact command line executed, or null>
violations: [<array of the schema above; empty if status == OK or NOT_CONFIGURED>]
error:      <only when status == ERROR: one-line reason, e.g. "vale not on PATH" or "yarn docs:lint exited 2 with unparseable output">
```

- `status: OK` — linter ran, produced zero violations.
- `status: NOT_CONFIGURED` — no primary linter configured AND `dt-style-guide` not installed (the fallback was unavailable).
- `status: VIOLATIONS_FOUND` — linter ran, produced ≥ 1 violation.
- `status: ERROR` — the primary linter failed AND the `dt-style-checker` fallback also failed. Only reached when no check of any kind could run.

## Hard rules

- NEVER modify files under `repo_root`. This agent reports; `doc-fixer` applies fixes.
- NEVER promote a MINOR / NIT style finding to BLOCKER. The linter's own severity is authoritative.
- NEVER run the whole-repo lint if a files-scoped invocation is available (performance + noise reduction). If Vale and markdownlint both accept per-file paths, pass only the input `files`.
- NEVER fabricate a `command` value — if no linter was detected, `command: null`.
- NEVER output a partially filled violation record (missing `file` or `line`). Drop such records from the output and note the count in `error` if it seems suspicious.
- Cap the run at 2 minutes total. If the linter has not finished, kill it and return `status: ERROR` with reason `linter timed out after 2 minutes`.
- If the linter emits warnings about its own configuration (e.g. "Vale: no styles found") rather than content, return `status: ERROR` with the reason; the main command should not pretend the check passed — but still attempt the dt-style-checker fallback first per the hard rule above.

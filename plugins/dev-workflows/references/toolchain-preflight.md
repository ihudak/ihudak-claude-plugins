# Toolchain preflight (shared)

Single source of truth for verifying, before a run writes anything, that the tools its gates invoke
are actually present.

Consumed by `/document` (both modes) at Phase 0. Pairs with
`${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` — the preflight decides whether to start; the ledger
records what actually happened.

---

## 1. Why this runs first

A `/document` run started in a container without `vale` and without `pnpm` still produces a branch, a
commit, and a PR draft. No linter ran and no server booted, so the documentation is worse — but the PR
exists and CI is green, and nothing signals that anything went wrong. The failure is silent, and it is
the run's own environment that caused it.

That is knowable at Phase 0 for the cost of one `command -v` per tool. Without a preflight the run
discovers it one gate at a time, at Phase 6.4 and Phase 6.5, after the documentation is written.

## 2. Deriving the required set

Run this **after profile resolution** — the profile is what names the commands. Union three sources;
de-duplicate by binary name.

1. **The resolved profile.** Take the **first whitespace-separated token** of every `commands.*` value
   (including every `commands.per_space.<space>.*` value) and every `dev_servers.servers[].command`.
   `"pnpm docs:lint"` ⇒ `pnpm`. Add every entry in `profile.prerequisites` as a named
   prerequisite (these are prose, not binaries — record them for reporting, and check them only when
   the prose names a checkable path or binary).
2. **Repo config signals**, checked at `repo_root`:

   | Signal file | Implies |
   |---|---|
   | `.vale.ini` | `vale` |
   | `pnpm-lock.yaml` | `pnpm` |
   | `package-lock.json` | `npm` |
   | `yarn.lock` | `yarn` |
   | `.markdownlint.json` / `.markdownlint.jsonc` | `markdownlint` |
   | `.remarkrc*` | `remark` |

   Separately, when any lockfile is present, check `node_modules/` as an **installed-dependencies**
   signal. A present `pnpm` with absent dependencies fails just as completely as a missing `pnpm`.
3. **The repo's documented prerequisites.** Grep `repo_root`'s `CONTRIBUTING.md`, `CONTRIBUTION.md`,
   and `README.md` for a heading matching `Prerequisites` (case-insensitive) and read that section.
   Best-effort: extract named tools and minimum versions where stated. Nothing found ⇒ contribute
   nothing. Never fail the preflight on an unparseable Prerequisites section.

**Direct mode has no profile.** `/document` Mode B resolves `repo_root` as cwd's git root and uses
sources **2 and 3 only**. Source 1 contributes nothing there. `/document` direct mode reads the same guidance files again in the same pass for `${CLAUDE_PLUGIN_ROOT}/references/repo-verification-gates.md` §2 — do both in one read, not two.

## 3. Checking

- Binaries: `command -v <binary>` — present when exit 0.
- Directory signals (`node_modules/`): `test -d`.
- Never install anything. Never modify the repo. This step is read-only.

## 4. The `toolchain` block

```yaml
toolchain:
  - tool: <binary name, or a directory signal such as "node_modules">
    status: present | missing
    source: <profile.commands | profile.prerequisites | .vale.ini | pnpm-lock.yaml | CONTRIBUTING.md Prerequisites | …>
    required_by: [<gate ids from gate-ledger.md §4>]
```

`required_by` maps each tool onto the gates it powers, which is what lets the preflight state the
run's outcome before the run:

| Tool | Typically required by |
|---|---|
| the repo's prose linter (`vale`, `markdownlint`, `remark`) | `style_check` |
| the package manager (`pnpm` / `npm` / `yarn`) | `style_check`, `build_check`, `render_smoke_check` |
| `node_modules` present | every gate the package manager powers |
| `git` | `source_truth_verification` |

Derive `required_by` from where the tool came from: a binary that appears only in
`commands.per_space.<space>.build` powers `build_check`; one that appears in a `dev_servers` command
powers `render_smoke_check`. A tool with an empty `required_by` is reported but never blocks.

## 5. Reporting and the prompt

**When every required tool is present, say nothing beyond one line in the caller's readiness output.**
A preflight that prompts on a healthy container becomes one more thing to click through, and dies the
way the Phase 6.4 gate died.

When one or more required tools are **missing**, print the `toolchain` rows (missing first), then the
consequence — each affected gate and the outcome it will record — then ask:

```
choices: ["Cancel — re-run in the docs container (Recommended)", "Continue anyway — record the degraded gates", "Other… (describe)"]
```

Example consequence line:

> With `vale` and `pnpm` missing, this run would record `style_check` **DEGRADED** (only
> `prose-style-checker` runs — the repo's own linter, the one CI will run on your PR, would not),
> `build_check` **UNAVAILABLE**, and `render_smoke_check` **UNAVAILABLE**.

- **"Cancel"** → stop the run. Nothing has been written.
- **"Continue anyway"** → for each gate named in the consequence line, **pre-seed** its ledger row's
  expected outcome and carry the user's choice verbatim, so that when the gate is reached its row
  records `SKIPPED_BY_USER` (or `DEGRADED` where a fallback does run) with `user_decision` already
  attributed. A pre-seeded row is still overwritten by what actually happens — a tool that turns out
  to work records `RAN`.

The preflight is itself a ledger gate: `toolchain_preflight`, phase 0, no fallback. Record its own row
(`RAN` when the check completed, whatever the findings; `FAILED` only if the check itself could not be
performed).

## 6. Location reporting

The caller has already resolved its target repo. The preflight does not re-resolve it — it reports
`repo_root`, and when `repo_root` differs from cwd it says so on its own line. **A divergence by
itself never prompts**: writing into `${DOCS_PATH:-/workspace/docs}` from a different working
directory is the normal AI-container case.

## 7. Hard rules

- NEVER install, upgrade, or configure a tool. Report and ask.
- NEVER modify any file under `repo_root`.
- NEVER prompt when every required tool is present.
- NEVER move the `(Recommended)` marker off "Cancel" in §5 — the "Choice lists are presented verbatim"
  rule in `escalation-rules.md` binds this prompt.
- NEVER fail the run because a `Prerequisites` section could not be parsed; source 3 is best-effort.
- NEVER treat a tool with an empty `required_by` as blocking.

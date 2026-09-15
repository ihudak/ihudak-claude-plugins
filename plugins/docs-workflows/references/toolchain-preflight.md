# Toolchain preflight (shared)

**Core references.** A citation of the form `workflows-core:<name>` names a shared reference in the `workflows-core` plugin. Load it with `Skill(skill: "workflows-core:reference", args: "<name>")` — never by path: `${CLAUDE_PLUGIN_ROOT}` resolves to this plugin, which does not carry it.

Single source of truth for verifying, before a run writes anything, that the tools its gates invoke
are actually present.

Consumed by `/document` (both modes) at Phase 0, and by `/docs-init` at Phase 2 step 3 — which **skips §2 entirely** and hands §3 a fixed set of its own (`git`, `python3`/`pip` or `uv`, `mkdocs`, `vale`). All three of §2's sources are empty for it: there is no profile yet, because it is the run that writes the first one; an absent or empty scaffold target carries no config signals; and it documents no `Prerequisites` of its own until this run has written them. It is the one consumer that derives nothing. Pairs with
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

1. **The resolved profile.** Take the **tool** of every `commands.*` value (including every
   `commands.per_space.<space>.*` value), every `builds[].command`, and every
   `dev_servers.servers[].command`. **A command's tool is its first whitespace-separated token that
   is neither part of a leading `cd <dir> &&` nor a leading `VAR=value` assignment**, set aside in
   whatever order they lead: `"pnpm docs:lint"` ⇒ `pnpm`; `"cd website && pnpm docs:build"` — the
   form `/docs-profile` records for a script found below the top level — ⇒ `pnpm`;
   `"NODE_ENV=production pnpm build"` ⇒ `pnpm`. The first token alone will not do: `cd` is a shell
   builtin, so `command -v cd` exits 0 on every host and every command it leads would read as
   runnable. This is the one definition of a command's tool; `docs-profiles/render-verification.md`
   §1 and `/document` Phase 6.5 Step 1 cite it. Where the profile records any
   `dev_servers.servers[]` entry, add
   `bash`, `curl` and `ps` too: the render smoke check that boots those servers starts and stops
   them under `bash`, probes their ports with `curl` and reads their process groups with `ps`, and
   cannot run without any of them (`docs-profiles/render-verification.md` §2). Add every entry in
   `profile.prerequisites` as a named prerequisite (these are prose, not binaries — record them for
   reporting, and check them only when the prose names a checkable path or binary).
2. **Repo config signals**, checked at `repo_root` — and, where the caller resolved the site to a
   directory below it, in that directory as well: `/document` keyed mode passes `docs_repo_resolved`
   (its Phase 0 step 2). A monorepo's site keeps its `.vale.ini`, lockfile and lint configuration
   beside itself, not at the top level. A signal found in either directory implies its tool, and so
   does a lockfile in any directory a profile command's leading `cd <dir>` names (source 1), taken
   relative to `repo_root` — that is where the command runs its tool:

   | Signal file | Implies |
   |---|---|
   | `.vale.ini` | `vale` |
   | `pnpm-lock.yaml` | `pnpm` |
   | `package-lock.json` | `npm` |
   | `yarn.lock` | `yarn` |
   | `.markdownlint.json` / `.markdownlint.jsonc` | `markdownlint` |
   | `.remarkrc*` | `remark` |

   Separately, when any lockfile is present, check `node_modules/` beside it as an
   **installed-dependencies** signal. A present `pnpm` with absent dependencies fails just as
   completely as a missing `pnpm`.
3. **The repo's documented prerequisites.** Grep `repo_root`'s `CONTRIBUTING.md`, `CONTRIBUTION.md`,
   and `README.md` for a heading matching `Prerequisites` (case-insensitive) and read that section.
   Best-effort: extract named tools and minimum versions where stated. Nothing found ⇒ contribute
   nothing. Never fail the preflight on an unparseable Prerequisites section.

**Direct mode has no profile.** `/document` Mode B resolves `repo_root` from **the edit target** — the directory it was given, or an `@file`'s directory — falling back to cwd only where the input names no path at all, and uses
sources **2 and 3 only**. It anchored on cwd unconditionally until a live run showed the consequence: invoked against one repository from inside another, the preflight read the repo it was standing in while the style check ran against the repo it was editing. Source 1 contributes nothing there. `/document` direct mode reads the same guidance files again in the same pass for `${CLAUDE_PLUGIN_ROOT}/references/repo-verification-gates.md` §2 — do both in one read, not two.

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
    required_by: [<gate ids from gate-ledger.md §4 whose primary mechanism runs this tool>]
    fallback_for: [<gate ids whose registered fallback runs it>]   # omitted when there are none
```

`required_by` and `fallback_for` map each tool onto the gates it powers, which is what lets the
preflight state the run's outcome before the run:

| Tool | Typically required by | Fallback for |
|---|---|---|
| the repo's prose linter (`vale`, `markdownlint`, `remark`) | `style_check` | — |
| the package manager (`pnpm` / `npm` / `yarn`) | `style_check`, `build_check`, `render_smoke_check` | `build_check`, where a dev-server command runs it |
| `node_modules` present | every gate the package manager powers | as the package manager |
| `git` | `source_truth_verification` | — |
| `bash`, `curl`, `ps` (the smoke check's own tools) | `render_smoke_check` | `build_check` |

Derive both from where the tool came from, a tool being a command's tool as §2 source 1 defines it:
the tool of a command `build_check` runs — a `builds[].command`, `commands.build`, or
`commands.per_space.<space>.build` (`docs-profiles/render-verification.md` §1) — powers
`build_check`; the tool of a `dev_servers` command powers `render_smoke_check`, and so do `bash`,
`curl` and `ps`, which that check runs itself. **Those same tools also run `build_check`'s
registered fallback** — the Step 2 dev-server boot that stands in for a build that will not run
(`gate-ledger.md` §4) — so each of them carries `fallback_for: [build_check]`. A tool with an empty
`required_by` is reported but never blocks.

## 5. Reporting and the prompt

**When every required tool is present, say nothing beyond one line in the caller's readiness output.**
A preflight that prompts on a healthy container becomes one more thing to click through, and dies the
way the Phase 6.4 gate died.

When one or more required tools are **missing**, print the `toolchain` rows (missing first), then the
consequence — each affected gate and the outcome it will record: `DEGRADED` where the gate's
registered fallback (`gate-ledger.md` §4) still runs without the missing tool, and `UNAVAILABLE`
where neither the primary nor the fallback can (`gate-ledger.md` §2). A gate is affected where a
missing tool's `required_by` names it, and its fallback still runs only where no missing tool's
`fallback_for` names it: with the build tool and `curl` both missing, `build_check` is
`UNAVAILABLE`, not `DEGRADED`, because the boot that stands in for the build probes its server with
`curl`. Then ask:

```
choices: ["Cancel — re-run in the docs container (Recommended)", "Continue anyway — record the degraded gates"]
```

Example consequence line:

> With `vale` and `pnpm` missing, this run would record `style_check` **DEGRADED** (only
> `prose-style-checker` runs — the repo's own linter, the one CI will run on your PR, would not),
> `build_check` **UNAVAILABLE** (its fallback, the dev-server boot, runs `pnpm` too), and
> `render_smoke_check` **DEGRADED** (no server can start without `pnpm`, so every affected page goes
> to the manual pages-to-visit table, the fallback that needs no tool).

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
  rule in `workflows-core:escalation-rules` binds this prompt.
- NEVER fail the run because a `Prerequisites` section could not be parsed; source 3 is best-effort.
- NEVER treat a tool with an empty `required_by` as blocking.

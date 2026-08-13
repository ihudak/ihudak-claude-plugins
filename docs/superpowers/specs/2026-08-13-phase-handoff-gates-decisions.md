# Sub-project J — phase handoff gates + PR-on-completion (decisions agreed 2026-08-13)

**Not yet specced.** Runs immediately after sub-project I. This file is the durable record of what
was agreed in conversation, so J's spec can be written without re-litigating any of it.

## The governing principle (user's words, paraphrased)

A workflow phase is not finished until its artifact is on `main`. A command that ends a phase must
commit, push, **and open a PR**. The command that starts the next phase refuses to run until the
previous artifact is on `main`.

The gate applies **even when the role does not change** — because it may be a different human of the
same role, and because even the same human should have to confirm the previous phase is done and
approved. `main` is the signal of readiness. Without the gate, the next person may struggle to find
the right files, or silently build on an older version.

## Agreed decisions

### 1. PR creation — the plugin opens it

`commit-artifacts` gains: commit → push → `gh pr create --title … --body-file …` when the host is
GitHub and `gh` is present; otherwise fall back to today's printed draft + instructions.
Reports e.g. `Specs repo: pushed, PR #124 open`.

- The specs repo is GitHub (`Dynatrace-Internal/mgd-specifications`); `gh` 2.97.0 is installed.
- `gh` is permitted under the project's zero-**direct**-API rule (it wraps the API rather than
  calling it over HTTPS), the same rationale `/document` already uses.
- **This reverses two existing NEVER rules** that must be revised in the same change:
  - `finish-and-handoff.md:74` — "The plugin never opens the PR itself" (and §5's "no API" framing).
  - `specs-repo-git.md:20` — "Nothing here opens a pull request or calls a REST API".
- It also **repairs an existing inconsistency**: `specs-repo-git.md:179` already reasons about "the
  very pull request the command opened for it one phase earlier" and `:291` about "the pull request
  already open" — the git layer was written assuming per-phase PRs that nothing ever created.

### 2. Gate coverage — every artifact handoff

| Producer | Consumer | Gate |
|---|---|---|
| `/idea` → `idea.md` | `/create-vi` | idea on main under `specifications/<KEY>-<slug>/` |
| `/create-vi` → VI | `/create-ard` | VI on main |
| VI (+ ARD when one applies) | `/specify` | both on main |
| `/specify` → `specification.md` | `/design` | spec on main |
| `/design` → `design.md` | `/implement` | design on main |
| the whole chain | `/ready` | verifies all of it |

### 3. Strictness — stop, with a repair choice

When the artifact is not on main:

- **Tree clean, or dirty only in the plugin's own artifact paths** → offer `switch to main +
  pull --ff-only` as a first-class choice, then re-run the resolution. This covers the common
  "the spec is just on the wrong branch by mistake" case. Reuses `specs-preflight`'s existing
  branch disposition (B1–B4) and artifact flush — no new machinery.
- **Dirty in a way that would block the switch** → hard stop naming the exact files, with the
  commands to resolve it and an instruction to re-run. **No silent stash, no forced switch.**
- When a PR is open but unmerged, the stop names it (`PR #124 (open, not merged)`).

### 4. `/idea` completes its own handoff — driven by `vi_disposition`

`/idea` Phase 5 already tells the user to "first create an empty Jira workitem". It now completes
the handshake, conditioned on the signal `/idea` already computes:

- **`vi_disposition: rewrite`** — the key is already known from the `vi` source. Relocate to
  `specifications/<KEY>-<slug>/idea.md` → commit → push → PR. **No human round trip.**
- **`vi_disposition: new`, status `refined`** — offer: "create the Jira workitem and give me the
  key, and I'll complete the handoff." On receiving the key, relocate → commit → push → PR. If the
  user declines, the idea stays in the vault and `/idea` reports plainly that it was **not handed
  off**.
- **status `draft`** (open clarifications outstanding) — **never hand off.** By the governing
  principle the phase is not finished; offer `--deep` or the explicit out-of-contract route.

**Rejected alternative:** a staging directory (e.g. `specifications/_inbox/<slug>/`) holding the
idea before the key exists. It puts unkeyed artifacts into a repo whose whole grammar is keyed and
creates an abandoned-idea cleanup problem, for a case the explicit `@<path>` route already covers.

### 5. `/create-vi`'s contract — explicit, and a breaking change

- **`/create-vi <KEY>`** — in-contract. Derives the idea's location from `<KEY>`
  (`specifications/<KEY>-<slug>/idea.md`, on main). The gate applies. **No relocation** — `/idea`
  already did it.
- **`/create-vi <KEY> @<path>`** — explicitly out-of-contract. Reads the idea where it sits,
  **does not move it**, gate does not apply.

The relocation responsibility moves from `/create-vi` to `/idea`. This is a **breaking change**:
call it out in the plugin README (describing how `/create-vi` handles its parameters) and in the
CHANGELOG under breaking changes.

### 6. Consequence for `specs-repo-git.md` §3.6

If an artifact must reach `main` before the next phase runs, the **cross-command branch stacking
§3.6 defends largely dissolves** — `/design` starts from a clean `main` rather than from
`/specify`'s branch. B3's "keep the working tree containing the artifact" rationale still holds
*within* a command. §3.6 must be revised accordingly; this is a revision to sub-project C's design,
not a contradiction of it.

### 7. Absorbed from sub-project I

Review finding **I3** (`/design`'s "spec is on main" gate is a working-tree file test that cannot
fire on the case it was written for, and contradicts §3.6) is **absorbed into J** and excluded from
sub-project I — no point building that gate twice.

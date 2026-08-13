# Read-only repository mounts (shared reference)

The AI container mounts repositories from the host, and some arrive **read-only** — verified 2026-08-11, 2 of 12 clones under `/workspace` are (`docs`, `observability-requirements`). Every agent that prepares a clone before reading it must work on those mounts rather than fail on them.

This file is the single source of truth for that behavior. Consumers: `code-scanner`, `diff-summarizer`, `docs-grounder` — the first two also emit the §6 `prep` block; `docs-grounder` consumes §1–§4 only.

**Nothing here changes behavior on a writable mount.** `git switch` and `git pull --ff-only` remain sanctioned prep on a writable clone — they change which committed revision is present, not the content of it. Everything below is reached only when the mount is read-only.

## 1. Detection

Before any git call that writes:

```
test -w "<repo_path>" && test -w "<repo_path>/.git"
```

Either test failing ⇒ **read-only mode**. Secondary trigger: any git command failing with an error containing `Read-only file system` ⇒ enter read-only mode and retry there, rather than returning `REFRESH_BLOCKED`.

A false positive is benign: the agent then reads at `origin/<default-branch>`, which is what a caller passing `switch_to_default_branch: true` or `refresh.pull: true` asked for anyway.

## 2. What read-only mode skips

- `git fetch`, `git pull`, `git switch`, `git remote set-head` — all write.
- **The dirty-tree gate.** A dirty working tree is irrelevant when the working tree is never mutated, so read-only mode NEVER returns `DIRTY_TREE`.

Read-only mode is not a failure. It NEVER returns `REFRESH_BLOCKED` on its own; that status stays reserved for a genuine failure — §3's chain exhausted, or §4's read primitives all failing.

## 3. Resolving the ref without writing

In order, stopping at the first that succeeds:

1. `git -C "<repo_path>" symbolic-ref --short refs/remotes/origin/HEAD`
2. `git -C "<repo_path>" rev-parse --verify origin/main`
3. `git -C "<repo_path>" rev-parse --verify origin/master`

`git remote set-head origin --auto` is **not** part of this chain — it writes. An exhausted chain is a genuine `REFRESH_BLOCKED` with reason `cannot resolve default branch on a read-only mount`.

Then record three facts, all pure reads:

- `git -C "<repo_path>" log -1 --format=%cI <ref>` → `ref_committed_at`
- `git -C "<repo_path>" rev-list --left-right --count <ref>...HEAD` → `behind` then `ahead`, tab-separated
- `git -C "<repo_path>" rev-parse --abbrev-ref HEAD` → the working-tree branch name

## 4. Reading at the ref

Two write-free scan targets:

- **The working tree**, with the native `Grep` / `Glob` / `Read` tools.
- **The ref**, via git plumbing that never consults or writes the index:
  - enumerate — `git -C "<repo_path>" ls-tree -r --name-only <ref>`
  - search — `git -C "<repo_path>" grep -n <pattern> <ref> -- <pathspec>`
  - read — `git -C "<repo_path>" show <ref>:<path>`

**When HEAD is already at the ref — `git -C "<repo_path>" rev-parse HEAD` equals `git -C "<repo_path>" rev-parse <ref>` — scan the working tree natively.** The content is identical and the native tools are better, so the common read-only case costs nothing extra.

Otherwise read at the ref. If `git grep <tree-ish>` is unavailable or errors, fall back to `git show`-per-file over an `ls-tree` shortlist. If that also fails, return `REFRESH_BLOCKED` with the one-line git error.

## 5. When to escalate

Escalate to the caller — which prompts the user per the `Read-only mount — ref stale or diverged` entry in `escalation-rules.md` — when **either** holds:

- `ref_committed_at` is more than **14 days** old — the host has not fetched recently, so the ref itself is stale; or
- `head_divergence.ahead > 0` — the working tree carries commits the ref does not, so local work is invisible at the scanned ref.

`head_divergence.behind > 0` alone is **silent**: the scan reads the ref, so being behind locally changes nothing. On a read-only mount sitting at the default branch with a recent ref, the run proceeds with no prompt.

## 6. Output contract

`code-scanner` and `diff-summarizer` report these four fields in their `prep` block, always present so a caller never branches on absence:

```yaml
prep:
  read_only:        true | false
  scanned_ref:      <ref name, e.g. "origin/main"; the default branch name when writable>
  ref_committed_at: <ISO-8601 timestamp of the ref's newest commit>
  head_divergence:  { branch: <working-tree branch>, ahead: <n>, behind: <n> }
```

`docs-grounder` follows §1–§4 (read-only detection, what to skip, ref resolution, reading at the ref) but returns a digest — `status` / `retrieval` / `docs_references` / `docs_challenges` / `notes` — not a `prep` block; its staleness signal is the 14-day clause in `docs-grounding.md` instead.

Every path an agent returns keeps its documented meaning — relative to the repo root — and denotes content **at `scanned_ref`**.

## 7. Caller contract

A caller that reads repository files directly, rather than through one of these agents, must first confirm `HEAD` is at the remote default ref — or cite the content via `scanned_ref` (`git -C "<repo_path>" show <scanned_ref>:<path>`). A working tree on an unmerged branch is not released behavior, and citing it as current is the failure this reference exists to prevent.

## 8. Hard rules

- NEVER edit, create, or delete files under `repo_path`. NEVER commit, cherry-pick, reset, rebase, or force.
- NEVER write to `.git` in read-only mode — that includes `git remote set-head`, `git fetch`, `git pull`, and `git switch`.
- NEVER delete an `index.lock`.
- NEVER make HTTPS / REST calls to any git host. All work is on the local clone.
- Read-only mode is never fatal: it degrades to reading at the ref and reports what it did.

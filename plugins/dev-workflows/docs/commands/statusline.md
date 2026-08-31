# /statusline

Installs the plugin's multi-line status line into your Claude Code settings, enabling the per-session cost snapshot session-cost reporting reads.

## Who runs it

`/statusline` runs outside the role pipeline — no role, no cost-attribution phase. [Workflow overview](../workflow.md#cross-cutting-commands) groups it under Setup and review utilities, and recommends running it first: install it once, right after installing the plugin, so the cost snapshot it enables is already in place before your first pipeline command runs.

**Claude Code ships its own built-in `/statusline` command** (backed by its own `statusline-setup` agent). The bare `/statusline` always resolves to that built-in, never to this one — **always type the qualified form, `/dev-workflows:statusline`.** Two other commands in this plugin collide with a Claude Code built-in the same way: [`/release-notes`](release-notes.md) and [`/upgrade`](upgrade.md). See [Workflow overview](../workflow.md) for the full three-name collision list.

## Synopsis

```
/dev-workflows:statusline
```

Takes no arguments. Phase 4 shows the exact settings change and asks you to confirm (`Install / Cancel / Other…`) before writing anything.

## What it needs

- **Local access to `~/.claude/settings.json`** and write access under `~/.claude/dev-workflows/` — nothing else. This command reads no `$SPECS_PATH`, runs no specs-repo preflight, and creates no branch.
- **`bash` and `jq`** — if `jq` is missing, the Phase 4 settings merge falls back to `python3` rather than hand-editing the JSON.

## What it produces

Installs the vendored script to a stable per-user path (`~/.claude/dev-workflows/statusline-command.sh`, `chmod +x`'d) and merges a `statusLine` block into `~/.claude/settings.json`, preserving every other key. **It is idempotent and backs up anything it would overwrite** — an existing `statusLine` block, or an existing installed script — suffixing `-2`, `-3`, … rather than clobbering a prior backup. Installing it also enables the per-session **cost snapshot** ("Option B") that [Session cost](../reference/session-cost.md) reads when computing `cost_statusline_usd`. **This is the only settings change the command makes**, and it never commits anything; every write stays under `~/.claude/` — though enabling the cost snapshot does change what every cost-emitting command's Session cost line reports.

## Gates

No reviewer, no branch, no commit. The one checkpoint is Phase 4's explicit confirmation prompt, shown against the exact settings diff, before anything is written.

## Example

```
/dev-workflows:statusline
```

Run this once, first, right after installing the plugin. It backs up any existing `statusLine` block or installed script, installs the script, merges the new block into `~/.claude/settings.json` on confirmation, and reports the paths touched. The status line takes effect on the next render or new session.

## See also

- [Workflow overview](../workflow.md) — the three-way command-name collision (`/release-notes`, `/upgrade`, `/statusline`) and where this command sits among the setup utilities.
- [Session cost](../reference/session-cost.md) — the Option B cost snapshot this command enables.
- [`/release-notes`](release-notes.md) and [`/upgrade`](upgrade.md) — the other two commands whose bare form also reaches a Claude Code built-in.

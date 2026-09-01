# ihudak-claude-plugins

Ivan Gudak's open-source Claude Code plugin marketplace.

## Plugins

| Plugin | Description |
|--------|-------------|
| [dev-workflows](plugins/dev-workflows/) | Twenty-seven slash commands for the PM → PA → PE → Dev pipeline, with Opus-backed planning and review gates. [Docs](plugins/dev-workflows/docs/README.md) |
| [prose-style](plugins/prose-style/) | Pluggable prose style enforcement: `/prose-review-pr`, `/prose-review-docs`, `/prose-style-refresh`, plus sub-agents `dev-workflows` uses for Epics and docs. Vendor-neutral, overridable baseline. |
| [obsidian-llm-wiki](plugins/obsidian-llm-wiki/) | Ten slash commands for compiling Obsidian vault knowledge into a persistent, cross-referenced wiki with task management; supports Claude Code and GitHub Copilot. |
| [acli](plugins/acli/) | Atlassian CLI (`acli`) skill for Jira and Confluence — search, work items, comments, attachments, boards, sprints, pages. From [pi-skill-acli](https://github.com/ziegenberg/pi-skill-acli) (MIT). |

## Prerequisites

- **Claude Code** — the plugins install into Claude Code (some `obsidian-llm-wiki` commands also support GitHub Copilot).
- **`superpowers`** *(recommended)* — the Claude Code plugin `dev-workflows` leans on for `/prompt-brainstorm` and its brainstorm → plan → subagent-driven-development flow. No hard dependency; commands degrade gracefully without it.
- **`gh` + `gh auth login`** *(recommended)* — enables reading GitHub PR diffs (`/document`, `/release-notes`); without it those commands fall back to local-git strategies.
- **`vale`** *(optional)* — a prose linter for docs; `dev-workflows` falls back to a repo lint script, then the `prose-style` plugin, when `vale` is absent.
- **Recommended environment: [`ihudak/ai-containers`](https://github.com/ihudak/ai-containers)** — mounts every repository and your specs repo under one `/workspace` umbrella (repos at `/workspace/<repo>`, the specs repo at `/workspace/specs`), so the default `$REPOS_PATH` (`/workspace`) and an exported `SPECS_PATH` just work; it also installs `gh` and mounts the host `gh` auth. Outside a container the commands still work — set `$REPOS_PATH` yourself and manage `gh` login.

## Installation

### 1. Add this marketplace to Claude Code (once)

```bash
claude plugin marketplace add ihudak/ihudak-claude-plugins
```

### 2. Install plugins

```bash
claude plugin install dev-workflows@ihudak-plugins
claude plugin install prose-style@ihudak-plugins
claude plugin install obsidian-llm-wiki@ihudak-plugins
claude plugin install acli@ihudak-plugins
```

### 3. Configure environment variables

`dev-workflows` resolves its inputs and outputs through three core environment variables — plus an optional, read-only `DOCS_PATH` for documentation grounding. Export them in your shell profile (or rely on the AI-Container defaults):

```bash
export SPECS_PATH="/workspace/specs"   # shared store: specifications, designs, ARDs
export REPOS_PATH="/workspace"         # where your code clones live (default: /workspace)
export DOCS_PATH="/workspace/docs"     # optional, read-only: product docs for grounding (default: /workspace/docs)
export GIT_USER_INITIALS="iv-gu"       # optional: branch prefix for every branch-creating command
```

- **`SPECS_PATH`** — the shared, team-visible store for a ticket's `specification.md` / `design.md` / ARD under `specifications/<KEY>-<slug>/…`. Required by the specs-authoring commands (`/create-prd`, `/create-ard`, `/specify`, `/design`, `/ready`); advisory for `/implement`; additive for `/document`.
- **`REPOS_PATH`** — where code clones live; a single directory or a colon-separated list. Defaults to `/workspace`. Repos are matched by their `git remote get-url origin` slug, not by directory name.
- **`DOCS_PATH`** *(optional)* — a **read-only** clone of the product documentation (default `/workspace/docs`). When it is an existing directory containing markdown, `/idea`, `/create-prd`, `/update-prd`, `/create-ard`, `/specify`, `/epics`, and `/release-notes` automatically ground on the existing shipped docs (via the read-only `docs-grounder` agent), and `/document` prefers it as a docs-repo discovery hint. Never written to; every miss is a silent, non-blocking skip. Disable per-run with `--no-docs`, or override the root with `--docs <path>`.
- **`GIT_USER_INITIALS`** *(optional)* — your branch identifier, used verbatim (no trailing `/`) by every branch-creating command: `/implement`, `/document`, `/docs-profile`, `/upgrade`, and `/vuln`. Branch naming is **repo-rule-first**: each command reads the target repo's own `CONTRIBUTING.md` / `README.md` / `DOCUMENTATION-GUIDELINES.md` / `CLAUDE.md` and follows the convention documented there. Where that convention has a name/initials segment — as `example-docs` does (`<your-name-or-initials>/<JIRA-ISSUE-KEY>-<short-branch-name>`) — this variable fills it, giving `iv-gu/PRODUCT-1234-add-oauth`. Where it has none (say a plain `feat/<slug>` repo), the convention is followed as written and no initials are injected. Only when a repo documents no convention at all does this variable become the whole prefix. When unset, the commands fall back to `git config user.initials`, then infer from existing branch names, then ask. Full algorithm: `plugins/dev-workflows/references/branch-naming.md`.

### 4. Run `/dev-workflows:statusline` first

After installing, run `/dev-workflows:statusline` once. It installs the `dev-workflows` multi-line status line (session identity, git, context, cost, tokens, rate limits) into `~/.claude/settings.json` and enables the Option-B snapshot used by session-cost reporting. It is idempotent and backs up anything it would overwrite, and it changes no workflow-command behavior.

```
/dev-workflows:statusline
```

> Claude Code ships its own built-in `/statusline` command (backed by the `statusline-setup` agent) that configures a plain, single-line status line. Since the plugin's command shares that name, typing the bare `/statusline` runs Claude Code's built-in flow instead — always use the fully-qualified `/dev-workflows:statusline` to install this plugin's status line.

### 5. Update after new releases

```bash
claude plugin marketplace update ihudak-plugins
```

## Directory structure

The environment variables expect these layouts:

```
$SPECS_PATH/                      # shared, team-visible store
  specifications/<KEY>-<slug>/    # specification.md, design.md, ARD (+ per-Epic subfolders)

$REPOS_PATH/                      # code clones (default /workspace)
  <repo>/                         # matched by git remote slug, not directory name

$DOCS_PATH/                       # optional, read-only: product docs clone (default /workspace/docs)
  ...                             # e.g. an example-docs checkout; searched for grounding, never written
```

## Adding new plugins

1. Create a subdirectory under `plugins/` with the plugin name.
2. Add `.claude-plugin/plugin.json` (name, description, author).
3. Add `commands/`, `agents/`, `hooks/`, and/or `skills/` as needed.
4. For hooks, add a `hooks/hooks.json` declaring the registrations.
5. Register the plugin in `.claude-plugin/marketplace.json`.
6. Commit and push to `main`.

## License

MIT — see [LICENSE](LICENSE).

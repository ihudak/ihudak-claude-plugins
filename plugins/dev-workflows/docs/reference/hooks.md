# Hooks reference

`dev-workflows` bundles three hooks, declared in `hooks/hooks.json` and installed automatically with the plugin — there is nothing to opt into separately. Every hook is advisory: **a hook never blocks Claude.** All three scripts end in an unconditional `exit 0` regardless of what they detect or whether their own logic errors out, by contract — a hook exists to notify or remind, never to gate a tool call.

| Hook | Event | Matcher | What it does |
|---|---|---|---|
| `notify-done` | `Stop` | — | Raises a cross-platform desktop notification, "Claude Code finished", at the end of every turn. |
| `preload-context` | `UserPromptSubmit` | — | On a matched `/implement`/`/epics`/`/vuln`/`/upgrade` prompt, injects git/model-routing/specs context; a near-instant no-op otherwise. |
| `test-notify` | `PostToolUse` | `Bash` | Detects a test-runner invocation, parses its pass/fail counts, and raises a desktop notification summarizing the result. |

The companion `docs-workflows` plugin ships its own pair — a `preload-context` covering `/document` and `/release-notes`, and the `changelog-owners-reminder` that warns about a docs page's changelog and owners frontmatter. The `changelog-owners-reminder` moved here entire, following the profile data it reads; `preload-context` was **split** rather than moved, so each plugin now preloads for its own commands and this plugin still ships one of its own.

## What each hook does, in detail

### `notify-done` (`hooks/notify-done.sh`)

Runs on every `Stop` event with no matcher, so it fires at the end of every turn regardless of what happened during it. It builds one fixed message, `"Claude Code finished"`, and dispatches it through the first notification mechanism available for the host: `osascript` when `$OSTYPE` starts with `darwin`, `wsl-notify-send` or a PowerShell balloon-tip fallback when `/proc/version` mentions Microsoft (WSL), and `notify-send` — falling back to a plain terminal bell (`echo -e '\a'`) if that binary is missing — everywhere else. Every branch degrades to a fallback rather than propagating a failure — the darwin branch is explicitly suffixed `|| true`, while the WSL and default branches instead fall through to `echo -e '\a'` (a terminal bell) when their own notifier command fails; the actual never-fails guarantee comes from the unconditional `exit 0` on the script's last line, regardless of which branch ran.

### `preload-context` (`hooks/preload-context.sh`)

Runs on every `UserPromptSubmit` event. It reads the submitted prompt from stdin JSON (trying the `prompt`, `user_prompt`, and `message` keys in turn for compatibility across Claude Code versions) and matches it against `^/(implement|epics|vuln|upgrade)[[:space:]]+[^[:space:]-]` — a recognized command name followed by at least one non-flag argument. Anything else, including a bare command with no argument, exits immediately with no output. For a match, it routes by command: `/implement`, `/vuln`, and `/upgrade` get full context (a model-routing reminder, the current branch, `git status --short`, the last 5 commits, and a directory listing when the cwd has 30 or fewer entries), plus specs context (`$REPOS_PATH`, `$SPECS_PATH`, and the current branch) when `/implement`'s own argument looks like an address; `/epics` always gets specs context, since it is keyed and accepts either an address or a folder in the specs tree. Every other command is not matched at all, so no context is injected for it — including `/document` and `/release-notes`, which the sibling `docs-workflows` plugin's hook of the same name matches instead. The two regexes are disjoint, so on a machine with both plugins installed both scripts run on every prompt and at most one of them emits.

### `test-notify` (`hooks/test-notify.sh`)

Runs on every `PostToolUse` event matched to the `Bash` tool. It reads the tool-call payload from stdin, extracting the executed command and its captured output (checking both the nested `tool_input`/`tool_response` shape and top-level fallback keys for older payload versions). If the command does not match one of `mvn test`, `gradlew test`, `gradle test`, `npm test`, `yarn test`, `pytest`, or `make test`, it exits immediately. For a match, a small embedded Python script parses tool-specific pass/fail counts out of the output — `Tests run:`/`Failures:`/`Errors:` for Maven, `N tests completed, N failed` for Gradle, `N passed, N failed` for pytest, and a `Tests: … passed … failed` line for npm/yarn — falling back to the literal string `"tests completed"` when no pattern matches, and raises a desktop notification (the same cross-platform dispatch as `notify-done`) reading `"Test run: <summary>"`.

## Why none of this blocks you

Every script above ends `exit 0` unconditionally — the exit code is never derived from what the hook found, so a missing notifier binary or an unparsed test-output format never stops a tool call, a turn, or the run itself. Two of the three also guard on `command -v python3` up front and exit 0 immediately when it is absent, degrading to silence rather than failing — `preload-context.sh:29` and `test-notify.sh:6`; `notify-done` carries no such guard because it never calls `python3` at all.

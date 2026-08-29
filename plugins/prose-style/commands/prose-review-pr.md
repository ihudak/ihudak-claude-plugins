---
name: prose-review-pr
description: >
  Reviews documentation changes from a pull request against the active prose style
  rules. Accepts a PR number (merge-commit convention) or a source branch name.
  Extracts changed markdown files, runs prose-style-checker, and optionally runs Vale
  if the repo has a .vale.ini. Reports violations with file, line, severity, and
  suggested fix.
allowed-tools: Read Bash Glob Grep Task
---

# Review documentation changes from a pull request

Reviews the markdown files changed in a pull request against the active prose style
rules — the plugin's vendor-neutral baseline, plus your organization's overlay when one
is configured. Outputs a structured violation report.

## Arguments

The command receives its input via `$ARGUMENTS`. Accepted formats:

| Format | Example | Behaviour |
|---|---|---|
| PR number | `9089` | Finds merge commit or remote branch for that PR |
| Branch name | `feat/improve-install-guide` | Diffs the branch against `main` |
| `--repo <path>` | `--repo /workspace/product-docs` | Override the repo path (default: current working directory) |
| `--doc-type <type>` | `--doc-type product-docs` | Passed to prose-style-checker for severity calibration (default: `product-docs`) |
| `--rules <path>` | `--rules ~/style/rules` | Override overlay discovery; passed to prose-style-checker as `rules_path` |

Arguments can be combined: `9089 --repo /workspace/product-docs`.

If no arguments are provided, ask the user for a PR number or branch name.

## Procedure

### 1. Parse arguments

Extract from `$ARGUMENTS`:
- **target**: the PR number (all digits) or branch name (anything else that is not a flag).
- **repo_path**: value after `--repo`, or the current working directory if absent.
- **doc_type**: value after `--doc-type`, or `product-docs` if absent.
- **rules_path**: value after `--rules`, or absent.

If no target is found, ask the user: "Please provide a PR number or source branch name."

### 2. Resolve changed files

Run every git command with `git -C <repo_path>`.

#### 2a. If target is a PR number

```bash
# Look for the merge commit in ALL branches/tags
git -C <repo_path> log --all --oneline --grep="Pull request #<NUMBER>:" | head -5
```

Repositories that use GitHub's default merge subject line record it differently — if
the search above finds nothing, retry with `--grep="(#<NUMBER>)"` before falling
through to the branch search.

- **Merge commit found** (PR is merged):
  - Extract the commit SHA.
  - Get the diff: `git -C <repo_path> diff <SHA>^..<SHA> --name-only -- '*.md'`
  - This gives the list of changed markdown files.

- **No merge commit** (PR is open/unmerged):
  - Search remote branches for the PR number or related branch:
    ```bash
    git -C <repo_path> fetch --all --prune 2>/dev/null
    git -C <repo_path> branch -r | grep -i "<NUMBER>" | head -5
    ```
  - If a matching remote branch is found, diff it:
    ```bash
    git -C <repo_path> diff origin/main...origin/<branch> --name-only -- '*.md'
    ```
  - If no branch is found, tell the user:
    "Could not find PR #<NUMBER> in the local git history or remote branches.
    Try providing the source branch name instead."

#### 2b. If target is a branch name

```bash
git -C <repo_path> fetch origin <branch> 2>/dev/null
git -C <repo_path> diff origin/main...origin/<branch> --name-only -- '*.md'
```

If the diff is empty, also try `main...<branch>` (local branch) and
`main...remotes/origin/<branch>`. If the repository's default branch is not `main`,
resolve it with `git -C <repo_path> symbolic-ref refs/remotes/origin/HEAD` and use that.

### 3. Filter to documentation files

From the list of changed files, keep only `.md` files. Exclude:
- `CHANGELOG.md`, `README.md`, `CONTRIBUTING.md`, `RELEASING.md` (repo meta files)
- Files under `node_modules/`, `.git/`, `vendor/`, `build/`, `dist/`

If no documentation files remain after filtering, report:
"No documentation markdown files were changed in this PR."

### 4. Verify files exist on disk

For each changed file, check if it exists in the working tree. Files that were
deleted in the PR won't exist — skip those and note them in the report.

For files that exist, resolve to absolute paths.

### 5. Run prose-style-checker

Invoke the `prose-style-checker` agent (`subagent_type: prose-style:prose-style-checker`)
with:

```yaml
files:      [<absolute paths of existing changed files>]
doc_type:   <doc_type from arguments>
rules_path: <rules_path from arguments, when provided>
```

Collect the violation report, including its `rules_source` field.

### 6. Run Vale (optional)

Check if `<repo_path>/.vale.ini` exists. If it does:

```bash
which vale 2>/dev/null || echo "NOT_INSTALLED"
```

If Vale is installed and `.vale.ini` exists, run it on the changed files:

```bash
git -C <repo_path> rev-parse --show-toplevel  # confirm the root, then:
vale --output=line <file1> <file2> ... 2>&1
```

Collect Vale findings separately. If Vale is not installed, note:
"Vale is not installed — skipping automated linting. Style check is based on
prose-style-checker only."

### 7. Get the diff context

For each file with violations, get the actual diff hunks to show what changed:

```bash
# For merged PRs:
git -C <repo_path> diff <SHA>^..<SHA> -- <file>

# For branches:
git -C <repo_path> diff origin/main...origin/<branch> -- <file>
```

This helps the user see violations in context of what was changed.

### 8. Report

Output a structured report:

```markdown
## PR review: #<NUMBER> (or branch: <name>)

### Summary
- Files changed: X documentation files (Y deleted, skipped)
- Rules: <rules_source — "baseline" or "overlay: <path>">
- Style violations: X (MAJOR: N, MINOR: N, NIT: N)
- Vale findings: X (error: N, warning: N, suggestion: N)  — or "N/A (Vale not available)"

### Violations by file

#### `<relative-path>`

| Line | Severity | Rule | Message | Suggestion |
|------|----------|------|---------|------------|
| 42   | MAJOR    | Prose.Terminology.WrongTerm | ... | ... |

<diff context showing the changed lines around the violation>

#### `<next-file>`
...

### Vale findings (if available)
<Vale output grouped by file>

### Deleted files (skipped)
- `path/to/deleted.md`

### Recommendations
<Top 3 most impactful things to fix, prioritised by severity>
```

The `Rules:` line is the only place the overlay is reported. Do not warn when no overlay
resolved — the baseline is a valid, complete rule set.

### 9. Offer to fix

After the report, ask:
"Would you like me to fix the violations I found? I can apply safe, mechanical
fixes (terminology, excluded words, formatting). Ambiguous cases will be skipped."

If the user says yes, invoke the `prose-fixer` agent
(`subagent_type: prose-style:prose-fixer`) with the violation list and the file paths.

## Hard rules

- **Work in any repo** — don't assume a particular docs-repo layout. Optimise for
  repos with a merge-commit convention (`Pull request #<N>: …` or `… (#<N>)`), and fall
  back to branch diffing when neither matches.
- **Never modify files** during the review phase. Fixes happen only via
  `prose-fixer` and only when the user explicitly approves.
- **Show violations in diff context** so the user can see what changed alongside
  what violated the style rules.
- **Respect .gitignore** — don't review generated or vendored files.
- **A missing overlay is never an error.** Report the resolved rule source once and
  move on.
- **If git operations fail**, report the error clearly and suggest the user
  provide a branch name or file paths directly.

---
name: prose-review-docs
description: >
  Reviews markdown documentation files or directories against the active prose style
  rules — the plugin's vendor-neutral baseline plus your organization's overlay when
  one is configured. Accepts a file path or directory (recursive). Runs
  prose-style-checker and optionally Vale. Supports --fix to auto-apply safe
  corrections via prose-fixer.
allowed-tools: Read Bash Glob Grep Edit Task
---

# Review documentation files against the prose style rules

Reviews one or more markdown files against the active prose style rules. Reports
violations and optionally applies fixes.

## Arguments

The command receives its input via `$ARGUMENTS`. Accepted formats:

| Format | Example | Behaviour |
|---|---|---|
| File path | `docs/get-started/index.md` | Reviews that single file |
| Directory path | `docs/get-started/` | Reviews all `.md` files recursively |
| `--fix` | `docs/ --fix` | After reviewing, apply safe mechanical fixes |
| `--doc-type <type>` | `--doc-type product-docs` | Severity calibration (default: `product-docs`) |
| `--severity <level>` | `--severity MINOR` | Only report violations at this level or above (default: show all) |
| `--rules <path>` | `--rules ~/style/rules` | Override overlay discovery; passed to prose-style-checker as `rules_path` |

Paths can be relative (resolved from cwd) or absolute. Multiple paths can be
provided: `docs/setup/ docs/config/auth.md`.

If no arguments are provided, ask the user: "Please provide a file or directory
path to review."

## Procedure

### 1. Parse arguments

Extract from `$ARGUMENTS`:
- **paths**: one or more file/directory paths (everything that is not a flag).
- **fix_mode**: `true` if `--fix` is present.
- **doc_type**: value after `--doc-type`, or `product-docs` if absent.
- **min_severity**: value after `--severity`, or `NIT` if absent (show all).
- **rules_path**: value after `--rules`, or absent.

If no paths are found, ask the user for a path.

### 2. Resolve files

For each path in `paths`:

- If it's a **file** and ends with `.md`: add it directly.
- If it's a **directory**: recursively find all `.md` files:
  ```bash
  find <path> -name '*.md' -not -path '*/node_modules/*' -not -path '*/.git/*' \
    -not -path '*/vendor/*' -not -path '*/build/*' -not -path '*/dist/*' \
    | sort
  ```
- If it **doesn't exist**: report a warning and continue with other paths.

Resolve all paths to absolute. Deduplicate.

If no files are found after resolution, report:
"No markdown files found at the specified path(s)."

### 3. Report scope

Before running the check, summarise:
"Reviewing **N** markdown file(s) in **M** director(y/ies) against the prose style
rules…"

If N > 50, warn: "Large review — this may take a while. Consider reviewing a
smaller subset."

### 4. Run prose-style-checker

Invoke the `prose-style-checker` agent (`subagent_type: prose-style:prose-style-checker`)
with:

```yaml
files:      [<absolute paths>]
doc_type:   <doc_type>
rules_path: <rules_path, when provided>
```

If there are more than 20 files, batch them in groups of 20 to avoid overloading
the agent context. Combine all results. The `rules_source` is the same for every batch;
report it once.

Collect the violation report.

### 5. Run Vale (optional)

Check if `.vale.ini` exists at or above the file paths. If it does and `vale` is
installed:

```bash
vale --output=line <file1> <file2> ... 2>&1
```

Collect Vale findings. Merge with prose-style-checker results, deduplicating where
both flag the same line for the same issue.

If Vale is not installed or no `.vale.ini` exists, note it and move on.

### 6. Filter by severity

If `min_severity` is set above NIT, filter out violations below that level.

Severity order: `BLOCKER > MAJOR > MINOR > NIT`.

### 7. Report

Output a structured report:

```markdown
## Documentation review

### Summary
- Files reviewed: N
- Rules: <rules_source — "baseline" or "overlay: <path>">
- Style violations: X (MAJOR: N, MINOR: N, NIT: N)
- Vale findings: X (error: N, warning: N, suggestion: N) — or "N/A"

### Violations by file

#### `<relative-path>`

| Line | Severity | Rule | Message | Suggestion |
|------|----------|------|---------|------------|
| 12   | MAJOR    | Prose.WordList.ExcludedWord | "blacklist" is excluded | Use "blocklist" or "denylist" |
| 45   | MINOR    | Prose.VoiceTone.PassiveVoice | Passive voice where the actor is known | Rewrite in active voice |

#### `<next-file>`
...

### Vale findings (if available)
<Vale output grouped by file>

### Top recommendations
1. <Most impactful fix>
2. <Second priority>
3. <Third priority>
```

The `Rules:` line is the only place the overlay is reported. Do not warn when no overlay
resolved — the baseline is a valid, complete rule set.

### 8. Fix mode

If `fix_mode` is `true`:

1. Show the report first (step 7).
2. Summarise what will be fixed:
   "**Fixable violations:** N out of M total. The following categories can be
   auto-fixed: terminology swaps, excluded-word replacements, formatting corrections.
   Ambiguous violations (voice/tone, structural) will be skipped."
3. Invoke the `prose-fixer` agent (`subagent_type: prose-style:prose-fixer`) with:
   - The violation list (filtered to fixable categories).
   - The file paths.
4. After fixing, re-run `prose-style-checker` on the modified files to verify.
5. Report the final state:
   "**Fixed:** N violations. **Remaining:** M violations (require manual review)."

If `fix_mode` is `false`, offer at the end:
"Run `/prose-review-docs <same-paths> --fix` to auto-fix the safe violations."

## Hard rules

- **In review-only mode (no --fix), NEVER modify files.** Report only.
- **In fix mode, only apply unambiguous fixes.** When in doubt, skip and report.
- **Batch large reviews** to avoid context overflow — max 20 files per checker
  invocation.
- **Relative paths in output** — show paths relative to cwd for readability.
- **Respect existing formatting** — don't reformat entire files when fixing
  individual violations.
- **A missing overlay is never an error.** Report the resolved rule source once and
  move on.
- **Deduplicate** — if Vale and prose-style-checker flag the same issue on the same
  line, report it once (prefer the prose-style-checker finding for consistency).

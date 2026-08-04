# Branch Naming (shared)

Single source of truth for how every command that creates a git branch selects the branch **prefix**. Each command still owns its own *slug* — see §2.

Commands that consume this: `/implement`, `/document` (both modes), `/docs-profile`, `/upgrade`, and `/vuln` (applied by `vuln-fixer` per the `/vuln` "Git Workflow" spec).

---

## 1. Prefix resolution ladder

Apply in order. **Stop at the first check that yields a non-empty value.**

### 1.1 `$GIT_USER_INITIALS`

```bash
echo "$GIT_USER_INITIALS"
```

If set and non-empty, use it as the prefix **verbatim** (never append a trailing `/` — the caller inserts it). This is the recommended way to lock an initials-prefix convention across every workflow and every repository. Examples: `GIT_USER_INITIALS=iv-gu` → prefix `iv-gu`; `GIT_USER_INITIALS=ivgu` → prefix `ivgu`.

### 1.2 `git config user.initials`

```bash
git -C <repo_path> config --get user.initials
```

Same semantics as §1.1. Set once per repo, or globally with `git config --global user.initials <initials>`, so the env var is not needed.

### 1.3 Inferred from existing branches

```bash
git -C <repo_path> --no-pager branch -a --format='%(refname:short)' 2>/dev/null | head -200
```

Scan for `<prefix>/<rest>` where `<prefix>` is **2–8 characters matching `[a-z0-9][a-z0-9-]*`** — so hyphenated initials (`iv-gu/`, `a-hue/`) count, as do unhyphenated ones (`ivgu/`, `jdoe/`, `mz23/`) and the generic prefixes (`feat/`, `docs/`, `fix/`, `chore/`, `feature/`, `bugfix/`, `hotfix/`, `release/`, `story/`).

Tally each candidate's frequency. Adopt a prefix when it accounts for **≥ 30 %** of the sample **and** occurs **≥ 3** times.

Tie-breaking:

- Prefer a **short non-generic** prefix (≤ 6 chars, not in the generic list above) with ≥ 3 occurrences over a generic one — that is the team convention; generic prefixes are usually older or external contributions.
- Among equally-ranked candidates of the same kind, prefer the **alphabetically first** for determinism.

### 1.4 Per-command fallback

| Command | Fallback prefix |
|---|---|
| `/implement` | `feat/` |
| `/document` (doc-edit mode) | `docs/` |
| `/document` (Jira mode) | `docs/` |
| `/docs-profile` | `docs/` |
| `/vuln` | `fix/` |
| `/upgrade` | `chore/` |

### 1.5 Mandatory escalation when §1.4 is reached

Reaching the fallback means detection found nothing. Before creating the branch, the command MUST ask (canonical wording in `escalation-rules.md` → "Branch prefix undetected"):

```
"I couldn't infer a branch prefix from $GIT_USER_INITIALS, `git config user.initials`, or existing branches. This command's default is `<fallback>`. What prefix should I use?"
choices: ["Use `<fallback>` (default for this command)", "Use my initials — I'll enter them", "Other… (describe)"]
```

On "Use my initials", prompt for the value:

```
"Enter your initials (lowercase; 2–8 characters from [a-z0-9-], starting with a letter or digit, e.g. `iv-gu` or `ivgu`; used as `<initials>/<slug>`):"
```

Then surface, once, without persisting anything:

> Tip: set `GIT_USER_INITIALS=<initials>` in your shell profile, or run `git config --global user.initials <initials>`, to skip this prompt next time.

---

## 2. Slug (owned by each command, unchanged by this doc)

- `/implement` — derived from the description: lowercase kebab-case, max 40 chars, punctuation and special characters stripped
- `/document` (doc-edit mode) — derived from the description: lowercase kebab-case, max 40 chars, punctuation and special characters stripped
- `/document` (Jira mode) — `<JIRA_KEY>-<first 4–6 content words of the VI summary>`
- `/docs-profile` — `NOISSUE-docs-profile`
- `/vuln` — `<JIRA-ID>-<CVE-ID>`, `NOJIRA-<CVE-ID>`, or `<CVE-ID>`
- `/upgrade` — `upgrade-<component>-to-<version>`, or `upgrade-<first>-and-<N>-more` for a batch

If `<prefix>/<slug>` already exists, append the first 7 chars of HEAD's SHA: `<prefix>/<slug>-<short-sha>`.

---

## 3. Resolution snippet

```bash
# Resolve branch prefix per references/branch-naming.md §1
prefix="${GIT_USER_INITIALS:-}"
if [ -z "$prefix" ]; then
  prefix="$(git -C "<repo>" config --get user.initials 2>/dev/null || true)"
fi
if [ -z "$prefix" ]; then
  prefix="$(git -C "<repo>" --no-pager branch -a --format='%(refname:short)' 2>/dev/null \
    | head -200 \
    | awk -F/ 'NF>=2 && length($1)>=2 && length($1)<=8 && $1 ~ /^[a-z0-9][a-z0-9-]*$/ {print $1}' \
    | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')"
fi
# Empty here → use the §1.4 fallback AND run the §1.5 escalation before branching.
```

---

## 4. Hard rules

- NEVER hard-code `docs/`, `feat/`, `fix/`, `chore/` or any other prefix as the only option — always run §1.1–§1.3 first.
- NEVER append a trailing `/` to a `$GIT_USER_INITIALS` or `user.initials` value; the caller inserts the separator.
- NEVER uppercase a prefix, and never use characters outside `[a-z0-9-]`; the first character must be a letter or digit (matching the §1.3 inference pattern).
- NEVER silently persist initials supplied through the §1.5 escalation — suggest the env var or git config instead.
- A branch-naming pattern documented in the **repo's own** guidance files (`CONTRIBUTING.md`, `CONTRIBUTION.md`, `README.md`, `DOCUMENTATION-GUIDELINES.md`) outranks this ladder for the overall **shape** of the name. This ladder still supplies the value for its `<user>` / `<initials>` / `<prefix>` placeholder.

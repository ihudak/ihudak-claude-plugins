# Source-Code Truth (Shared Policy)

This document is the **single source of truth** for one of the most important
rules in the `dev-workflows` plugin:

> **Verify against the implementation; escalate every discrepancy to the user.**
> The source code is what customers will use. Jira tickets, PRDs, design specs,
> and prose descriptions are the *starting point*, not the *spec* — they may
> be outdated, aspirational, simplified, or wrong. Every user-visible claim in
> generated documentation MUST be verified against the implementation, and
> every disagreement between the description and the source MUST be surfaced
> to the user for an explicit decision. **The plugin is the analyst; the user
> is the decision-maker.** The plugin never silently picks a winner.

Every sub-agent that synthesises documentation (`doc-planner`,
`doc-reviewer`, `release-notes-writer`) MUST apply this principle.

---

## 1. The principle

Customers do not read your Jira tickets. They read the docs, click the UI,
hit the API. So the docs must reflect what shipped — but the *what shipped*
question is sometimes a product-management question, not a code-truth question.

When a Jira ticket says "user picks Latest / Previous / specific version" and
the source code shows four presets (Latest / Previous / **Older** / specific),
that's a discrepancy. The plugin **doesn't** automatically pick one side;
it presents the discrepancy and asks the user. The user has context the plugin
doesn't (PM intent, sprint planning, agreed scope, customer expectations).

The user might decide:

- **"Document as source suggests"** — the implementation is the spec; update
  Jira separately. Often the right call: the implementer found extra value
  or the Jira was simplified for stakeholder consumption.
- **"Document as Jira claims"** — the implementation has a gap; the docs
  should describe what was *promised*, the user reports a bug against the
  team, and the doc PR holds until the gap is closed. Often the right call
  when shipping a feature with an acceptance contract.
- **"Skip this claim and report"** — neither side is wrong, but the discrepancy
  is too subtle to ship docs around; flag it for the team and leave the
  paragraph out for now.

The plugin's job is to **detect the discrepancy and present the analysis** in
the form of a table:

| # | Claim | Jira phrasing | Source phrasing | Source location | Verdict |

with one row per discrepancy and three per-row choices. See §7 for the
escalation protocol.

If the description and the code AGREE, the docs still cite the verified
source so they do not silently drift when a future ticket revision diverges
from what shipped.

## 2. What MUST be verified

For every documentation page, snippet, or release-notes entry produced by
this plugin, verify the following classes of user-visible claim against the
source code:

| Claim type | Where to verify in code |
|---|---|
| **Enum / dropdown options** (e.g. "Latest / Previous / Older stable") | Settings schema JSON (`*.schema.json` under `settings-schemas/`), data source classes (`*DataSource.java`), Java/TypeScript `enum` declarations, OpenAPI schema `enum:` fields |
| **UI labels and button text** (e.g. "Add update window", "Update now to target version") | `displayName:` / `label:` / `title:` constants in schema JSON, `i18n` / `.properties` resource bundles, React/Angular templates, `addItemButton:` metadata in schema files |
| **Menu paths** (e.g. "Settings > Deployment > ActiveGate updates") | UI route definitions, navigation manifests, `schemaGroups:` in schema files, `meta:` blocks |
| **Default values** | Schema `default:` fields, constant declarations (`DEFAULT_*`, `final static …`), `uiDefaultValue:` metadata |
| **Feature flags / maturity gates** | `featureFlag:` metadata in schemas, `@FeatureFlag` annotations, FF config files |
| **API endpoint paths, params, response shapes** | OpenAPI specs in the source repo, REST controller / resource implementations, request/response DTOs |
| **Field nullability / validation rules** | Schema `nullable:`, `minObjects:`, `precondition:` blocks; validator classes; `@Nonnull` annotations |
| **Concurrency / scope rules** ("one AG per group, one per zone") | Algorithm implementations, throttle/lock classes, scope filter expressions |
| **Permission / role gates** | Access-rule classes (`*AccessRule.java`), `@RequiresPermission` annotations, IAM scope declarations |
| **Headline counts** ("3 options", "4 modes", "supports X variants") | Always derived from the enumeration in the source; never copied from the description |

## 3. How to verify (techniques)

Sub-agents performing verification SHOULD use these techniques in order of
specificity:

### 3.1 Settings schema JSON (highest signal)

```bash
find <repo_path> -name "*.schema.json" 2>/dev/null \
  | xargs grep -l "<schema-id-or-keyword>" 2>/dev/null
```

Then read the file. Schema JSON declares the canonical enums, defaults,
validators, and UI labels. If the doc topic touches a Settings 2.0 feature,
this is the most reliable source.

### 3.2 Data source / option provider classes

When schema fields are dynamically populated (e.g. `subType: "datasource"`
in the schema), the runtime options come from a Java/TypeScript class
referenced by the schema's `datasource.identifier`:

```bash
grep -rn "DATA_SOURCE_ID = \"<identifier>\"" <repo_path> --include="*.java"
```

Read the class to find the actual option values and their display names.

### 3.3 Constant declarations

```bash
grep -rn "public static final String <NAME>\|const <NAME> =" <repo_path>
```

### 3.4 OpenAPI specs

```bash
find <repo_path> -name "openapi*.yaml" -o -name "openapi*.json" 2>/dev/null
```

For REST endpoint documentation, the OpenAPI spec is authoritative for
paths, params, request/response shapes, and enum values.

### 3.5 UI source

For button labels, menu items, and React/Angular templates:

```bash
grep -rn "<exact-string-the-doc-uses>" <repo_path>/ui --include="*.ts" --include="*.tsx" --include="*.html"
```

### 3.6 Tests as a fallback

If neither schema nor code yields the answer, test files often encode the
shipped behaviour:

```bash
grep -rn "<feature-name>" <repo_path> --include="*Test.java" --include="*.spec.ts"
```

## 4. Sub-agent responsibilities

### 4.1 `diff-summarizer` (use case A)

When summarising a PR diff, surface enum changes, new schema files, new
constants, and renamed labels in the per-PR summary. These are
high-signal evidence for downstream verification.

### 4.2 `doc-planner` (use case A)

The orchestrator passes `code_repos:` as an input — a list of
`{slug, path}` records pointing to the local clones used by the
diff-summarizer. doc-planner MUST:

1. Extract every user-visible claim from the proposed checklist (option
   names, button labels, default values, counts, menu paths, mode names,
   schema field names, UI flow steps).
2. For each claim, run the appropriate technique from §3 against the
   `code_repos` to verify the claim.
3. For each claim, emit a `verification_warnings` entry with one of these
   findings (added v1.8.0 — finer-grained than v1.7.0):
   - **`VERIFIED`** — source agrees with the claim. (Recommend omitting from
     the list to reduce noise; OR include with a single line for audit.)
   - **`CONTRADICTED`** — source has a different value/label/count. Record
     BOTH the `jira_phrasing` AND the `source_phrasing` verbatim. Do NOT
     pick a winner.
   - **`NOT_FOUND`** — Jira mentioned a behavior/UI element that has zero
     trace in the source. Implementation-gap candidate. Record the Jira
     phrasing and the locations checked.
   - **`AMBIGUOUS`** — multiple plausible source matches with different
     phrasing; verification can't pick one.
4. **Do NOT rewrite the topic notes to match the source** (v1.8.0 change).
   Leave the claim as the Jira description had it; the orchestrator will
   prompt the user per discrepancy at Phase 5.8 (impl-jira) and the user
   decides whether to use Jira phrasing, source phrasing, or skip.

### 4.3 `doc-reviewer` (use case A)

The orchestrator also passes `code_repos:` to the reviewer. The reviewer
runs the **Source-code accuracy** dimension: spot-check 3–5 user-visible
claims per file against the source using §3 techniques. **Severity rule
(updated v1.8.0):** a documented claim that does NOT appear in the source
is a **BLOCKER** UNLESS the doc contains an explicit intentional-discrepancy
marker explaining the gap. See §7 for the marker format.

**Note on `release-notes-writer`:** This agent applies the same source-truth verification to the specific option/label/count claims its draft makes (when `code_repos` is provided), recording discrepancies in its `gaps[]` for the release-notes command to escalate to the user.

## 5. Hard rules

- NEVER copy a Jira description's option list, count, label, or default
  value into the docs without running source verification on it.
- NEVER trust a Jira ticket's "User Story" section as the spec — it is
  the customer-narrative phrasing, often simplified.
- NEVER trust a Jira ticket's date — descriptions are often months old
  and may pre-date the actual implementation.
- **NEVER silently pick a winner** when source and description disagree
  (changed in v1.8.0). The plugin is the analyst; the user is the
  decision-maker. See §7 for the escalation protocol.
- When source verification is impossible (no code repos provided, source
  not yet implemented, generated code), surface that as a
  `verification_warning` with `finding: NOT_FOUND` and
  `technique: "no-source-evidence"` — never silently emit unverified
  user-visible claims.
- Reviewer severity rule: a customer-visible option / label / count
  that does not appear in the source is **BLOCKER**, not CONCERN —
  unless an intentional-discrepancy marker is present (§7).
- Bug-report draft destination is the same vault project folder used for
  the release-notes draft (auto-discovered by the orchestrator at
  `<vault>/Projects/Products/**/<JIRA_KEY>*`). File name:
  `<JIRA_KEY>-implementation-gaps.md`. Same hard rule as for release-notes:
  **NEVER `/tmp/`** — container restarts wipe it.

## 6. Example (real, from PRODUCT-14902)

Jira "User Story" said:

> A specific stable version available on the cluster (e.g., `1.327`).
> [implied 3 presets: Latest / Previous / specific]

Source — `cluster-repo/shared/core.platform.autoupdate/src/main/java/com/dynatrace/core/platform/autoupdate/activegate/settings/datasource/PrivateActiveGateAutoUpdateDataSource.java` lines 35–38:

```java
public static final String LATEST_VALUE = "latest";
public static final String PREVIOUS_VALUE = "previous";
public static final String OLDER_VALUE = "older";

private static final int ENTRY_LIMIT = 3; // only latest, previous and older can be selected
```

The source shipped **4 options** (Latest / Previous / **Older** / specific
main version). The Jira "User Story" missed "Older".

- v1.6.0 shipped the 3-option Jira phrasing — caught only in a manual
  review round.
- v1.7.0 added source verification but defaulted to silently picking the
  source side.
- v1.8.0 surfaces the discrepancy as a §7 table and asks the user.

A complementary example from the same VI, also caught by manual review:
the Jira "UI changes" section described renaming `Settings > Updates` to
`Settings > Deployment`. The source (`ClusterSettingsMenu.java:1404`)
still has `.withTitle("Updates")` — zero hits for any "Deployment" rename
anywhere in the cluster repo. v1.7.0 would have rewritten the doc to say
"Settings > Updates"; v1.8.0 instead presents the discrepancy and lets the
user decide whether to document the *shipped* path or document the *promised*
path and file a bug against the implementation team for the missing rename.

---

## 7. Discrepancy escalation protocol (added v1.8.0)

When `doc-planner` (or any sub-agent doing source verification) emits one
or more `verification_warnings` with finding `CONTRADICTED`, `NOT_FOUND`,
or `AMBIGUOUS`, the orchestrator MUST follow this protocol before
proceeding to Phase 6 (writing).

### 7.1 Present the analysis table

Build a single ask_user prompt showing every discrepancy in a table:

```
| # | Claim                          | Jira phrasing                              | Source phrasing                       | Source location                                | Verdict       |
|---|--------------------------------|--------------------------------------------|----------------------------------------|------------------------------------------------|---------------|
| 1 | Target version preset list     | "Latest stable, Previous stable, specific" | "Latest, Previous, Older, specific"    | …/PrivateActiveGateAutoUpdateDataSource.java:35 | CONTRADICTED  |
| 2 | Menu rename                    | "Settings > Updates → Settings > Deployment" | "Settings > Updates" (unchanged)     | …/ClusterSettingsMenu.java:1404                | NOT_FOUND     |
```

This table is informational — display it before asking decisions.

### 7.2 Ask the user how to proceed (batch first)

```
ask_user(
  question: "<N> discrepancies between the Jira description and the source code were found (see table above). How would you like to handle them?",
  choices: [
    "Decide per discrepancy (Recommended)",
    "Apply 'document as source suggests' to ALL",
    "Apply 'document as Jira claims' to ALL (will draft a bug report for the team)",
    "Apply 'skip and report' to ALL (will draft a bug report; no claims documented)",
    "Cancel"
  ]
)
```

### 7.3 Per-discrepancy decision (if user chose "Decide per discrepancy")

For each discrepancy in turn:

```
ask_user(
  question: "Discrepancy #<n>: <claim>\n  - Jira: <jira_phrasing>\n  - Source: <source_phrasing>\n  - Source location: <file:line>\n\nHow would you like to handle this one?",
  choices: [
    "Document as source suggests (Recommended for CONTRADICTED) — match what shipped; users see what's there",
    "Document as Jira claims — describe the promised behaviour; the orchestrator will add a TODO/bug-report draft so you can file a defect against the team",
    "Skip this claim entirely and report it — the docs leave this paragraph out; the bug-report draft still records the gap",
    "Cancel the whole run"
  ]
)
```

### 7.4 Record decisions

Maintain a `discrepancy_decisions` record keyed by discrepancy number:

```yaml
discrepancy_decisions:
  - number:           1
    claim:            "Target version preset list"
    jira_phrasing:    "Latest stable, Previous stable, specific"
    source_phrasing:  "Latest, Previous, Older, specific"
    source_location:  ".../PrivateActiveGateAutoUpdateDataSource.java:35"
    decision:         "document-as-source"
    rationale:        <user-provided text if "Other...">
  - number:           2
    claim:            "Menu rename"
    jira_phrasing:    "Settings > Updates → Settings > Deployment"
    source_phrasing:  "Settings > Updates (unchanged)"
    source_location:  ".../ClusterSettingsMenu.java:1404"
    decision:         "skip-and-report"
    rationale:        <user text>
```

Pass this record to Phase 6 (writer). The writer:

- For `document-as-source` decisions: use the source phrasing verbatim in
  the docs.
- For `document-as-jira` decisions: use the Jira phrasing AND insert an
  intentional-discrepancy marker (see §7.6) at the start of the
  enclosing section.
- For `skip-and-report` decisions: omit the claim from the docs entirely.

### 7.5 Emit the bug-report draft

When `discrepancy_decisions` contains ANY entry with decision
`document-as-jira` or `skip-and-report`, the writer MUST emit a Markdown
file alongside the release-notes draft at the auto-discovered vault
project folder:

```
<vault>/Projects/Products/**/<JIRA_KEY>*/<JIRA_KEY>-implementation-gaps.md
```

Format:

```markdown
# <JIRA_KEY> — Implementation gaps found during documentation

Generated <YYYY-MM-DD>. File these as defects against the implementation
team (or amend the Jira ticket if the gap is intentional).

## Gap <n>: <claim>

- **Jira phrasing**: <jira_phrasing>
- **Source state**: <source_phrasing>
- **Source location**: <file:line>
- **User decision in docs**: <decision>
- **Docs status**: <"described as Jira claims, awaiting implementation"
                    | "omitted from docs">
- **Suggested action**: file a Jira defect against the team that owns
  <source_location>'s component. Include a link to <JIRA_KEY> and a link
  to this gap analysis.
```

The bug-report draft uses the same hard-rule for destination as the
release-notes draft (vault, never `/tmp/`, never inside the docs repo).

### 7.6 Intentional-discrepancy marker format (for the writer)

For `document-as-jira` decisions, the writer inserts this marker
immediately before the affected prose:

```markdown
<!-- intentional-discrepancy: Jira <JIRA_KEY> describes
"<jira_phrasing>" but the source at <file:line> currently has
"<source_phrasing>". User decision: document Jira phrasing pending
implementation. See <vault-path>/<JIRA_KEY>-implementation-gaps.md gap #<n>. -->
```

`doc-reviewer`'s Source-code accuracy dimension (§4.3) recognises this
marker and treats the discrepancy as intentional (not BLOCKER) when it
is present.

### 7.7 When source-verification is impossible

If the orchestrator didn't pass `code_repos`, OR the code repos are
empty/unreachable: doc-planner emits a single `verification_warnings`
entry per user-visible claim with `finding: NOT_FOUND`,
`technique: "no-source-evidence"`. The orchestrator presents the same
§7.1 table (with `Source phrasing: "(not verifiable)"`) and the same
§7.2/§7.3 prompts; "Document as Jira claims" is then the natural
default since no source-side phrasing is available.

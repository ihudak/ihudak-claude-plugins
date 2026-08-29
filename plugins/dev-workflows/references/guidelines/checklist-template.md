# UI Guideline Compliance Checklist

**App/Component:** _________________
**Reviewer:** _________________
**Date:** _________________
**Guideline set version / commit:** _________________

> Reference files: `appheader.md`, `datatable.md`, `filterfield.md`, `connections.md`, `permissions.md`, `settings.md`, `dashboards.md`, `alerting-terminology.md`, `data-naming.md`, `accessibility.md`.
> Mark each item Pass / Fail / N/A. An item marked N/A needs a one-line reason in Notes.

---

## App header / top app bar (if applicable)

- [ ] A single app header renders on every page with identical contents and ordering
- [ ] App identity is present and links to the app's home destination (first tab, where tabbed)
- [ ] A help entry point is present, in the same position on every page
- [ ] A settings entry point is present where the app has configurable settings
- [ ] Menu order: settings inboard of help, both at the trailing edge
- [ ] Every icon-only header control has an accessible name and a matching tooltip
- [ ] Tabs implement the APG tabs pattern (arrow-key traversal, single tab stop, `aria-selected`)
- [ ] At most two app-wide action items, styled low-emphasis
- [ ] Header collapses responsively without dropping any entry point

**Notes:**

---

## Data table (if applicable)

- [ ] Loading state implemented (skeleton or progress indicator)
- [ ] Empty state implemented, and "no results" is distinguishable from "no data yet"
- [ ] Keyboard model follows the APG grid pattern (one tab stop in, arrow keys between cells)
- [ ] Header cells are marked up as header cells with an explicit scope
- [ ] Selection behaviour is consistent; bulk actions appear only on a non-empty selection and state the count
- [ ] Sort state is visible and exposed via `aria-sort`
- [ ] Actions sit at the right scope: table toolbar / column menu / row actions column / bulk bar / cell
- [ ] Row click discloses in context; links are used only for navigation away
- [ ] Pagination or virtualisation for large result sets, with the total row count visible
- [ ] Interactive targets are at least 24×24 CSS px, or adequately spaced
- [ ] A focused row stays visible under sticky headers and bulk bars

**Notes:**

---

## Filter field (if applicable)

- [ ] Only one filtering control scopes the dataset (no filter field + filter bar over the same data)
- [ ] Positioned above the content it scopes, in DOM and reading order
- [ ] Persistent visible label (not placeholder-only)
- [ ] Suggestion requests debounced at least 300 ms after the last keystroke
- [ ] Suggestions cached; superseded requests cancelled
- [ ] Syntax errors reported inline, associated via `aria-describedby`, field marked `aria-invalid`
- [ ] Filters apply only on explicit user action, never while typing
- [ ] Apply control is always operable; state is communicated by style, not by disabling
- [ ] `Cmd/Ctrl+Enter` applies; result count announced via a live region
- [ ] Grammar documented and linked from the field

**Notes:**

---

## Connection experiences (if applicable)

- [ ] Connections are discoverable in one place, grouped by ingest vs. outbound
- [ ] Every connection has a mandatory, unique display name
- [ ] Connection status is visible and its failure cause is specific
- [ ] "Test connection" performs a real round trip and names the concrete failure
- [ ] Credentials go to a secret store, are masked in edit, and are never echoed back
- [ ] OAuth flows follow RFC 6749 / 8252 / 9700 (authorization code + PKCE where supported)
- [ ] Create/edit dialogs follow the APG modal dialog pattern and confirm discard when dirty
- [ ] Delete confirms, naming the connection and warning about dependants
- [ ] Success and failure are both reported

**Notes:**

---

## Missing permissions (if applicable)

- [ ] Blocked controls stay visible and disabled, never hidden
- [ ] The missing permission is named concretely, in a copyable block
- [ ] The copyable block carries message, permissions, environment, app, user, and timestamp
- [ ] Disabled controls use `aria-disabled` and keep their explanation keyboard-reachable
- [ ] The explanation shows on focus as well as hover; no CTA lives inside a tooltip
- [ ] Multiple missing permissions are merged into one message region
- [ ] Policy structure is never disclosed; conditional-access cases say "no data available"
- [ ] Permissions are enforced server-side, not only in the UI

**Notes:**

---

## Settings (if applicable)

- [ ] The page is reachable from the product's central settings navigation
- [ ] Title matches the navigation entry; description says what it controls and who it affects
- [ ] Every field has a visible, programmatically associated label
- [ ] Shared changes require an explicit confirm — never save on blur or on toggle
- [ ] Destructive actions are marked destructive and confirm, naming the object
- [ ] Success and failure are both reported
- [ ] Default values are sensible and produce a working configuration
- [ ] Empty state has a mandatory title and a primary action matching the table's button
- [ ] All strings are externalised for translation; layout survives 200% text expansion

**Notes:**

---

## Dashboards (if applicable)

- [ ] Renders with no errors or warnings in the default configuration, on a fresh account
- [ ] Introduction tile present: H3 title ≤50 chars, value statement ≤300 chars, 1–2 getting-started links
- [ ] Most decision-relevant tiles above the fold (768–1080 CSS px)
- [ ] Row caps respected: ≤6 single-value tiles or ≤4 heavy tiles
- [ ] Threshold and status colours come from semantic colour roles, not hard-coded hex
- [ ] Contrast passes in every shipped theme; no state is conveyed by colour alone
- [ ] Chart types match the question (trend → line, comparison → bar, detail → table)
- [ ] Per-tile loading state present; "no data" distinguishable from an error
- [ ] Layout reflows to ~650 CSS px without two-dimensional scrolling

**Notes:**

---

## Terminology

- [ ] "Alert" is used for signals requiring timely action
- [ ] "Notification" is used for messages requiring no timely action
- [ ] One canonical name per capability across UI, API, settings, and docs
- [ ] Terms match the product's content style guide and appear in the glossary

**Notes:**

---

## Data naming (if applicable)

- [ ] Table, view, and dataset names describe content in user vocabulary
- [ ] One casing and namespace convention applied consistently
- [ ] Units stated in the name or in metadata, never implicit
- [ ] No published name renamed or removed without an alias and a deprecation date
- [ ] No internal code names, environments, or storage details in published names

**Notes:**

---

## Accessibility (WCAG 2.2 AA)

- [ ] Informative images have meaningful `alt`; decorative images have `alt=""`
- [ ] Icon-only controls have accessible names matching their tooltips
- [ ] Everything operable by pointer is operable by keyboard, with no keyboard trap
- [ ] Focus indicators are visible, contrast-compliant, and never obscured
- [ ] Text contrast ≥4.5:1; UI components and meaningful graphics ≥3:1
- [ ] No information conveyed by colour alone
- [ ] Every input has a visible, persistent, programmatically associated label
- [ ] Async results announced via live regions (SC 4.1.3)
- [ ] Targets ≥24×24 CSS px; drag operations have a single-pointer alternative
- [ ] Reflows to 320 CSS px without two-dimensional scrolling
- [ ] Verified with a screen reader, not only by code reading

**Notes:**

---

## Summary

| Category | Status | Critical Issues |
|----------|--------|-----------------|
| App header | Pass/Fail/N/A | |
| Data table | Pass/Fail/N/A | |
| Filter field | Pass/Fail/N/A | |
| Connections | Pass/Fail/N/A | |
| Permissions | Pass/Fail/N/A | |
| Settings | Pass/Fail/N/A | |
| Dashboards | Pass/Fail/N/A | |
| Terminology | Pass/Fail/N/A | |
| Data naming | Pass/Fail/N/A | |
| Accessibility | Pass/Fail/N/A | |

**Overall Status:** _________________

**Blocking Issues:**

**Recommendations:**

**Automated check run:** `python3 check_guidelines.py <path>` — output attached / summarised:

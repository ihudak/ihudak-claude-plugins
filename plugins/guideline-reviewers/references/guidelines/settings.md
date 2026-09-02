# Creating Settings

**Sources:** [Apple HIG: Settings](https://developer.apple.com/design/human-interface-guidelines/settings) · [Apple HIG: Entering data](https://developer.apple.com/design/human-interface-guidelines/entering-data) · [Apple HIG: Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets) · [Material 3: Lists](https://m3.material.io/components/lists/guidelines) · [Material 3: Switch](https://m3.material.io/components/switch/guidelines) · [Material 3: Dialogs](https://m3.material.io/components/dialogs/guidelines) · [Material 2: Empty states](https://m2.material.io/design/communication/empty-states.html) · [W3C WAI Forms: Labels](https://www.w3.org/WAI/tutorials/forms/labels/) · [NN/g: Confirmation Dialogs](https://www.nngroup.com/articles/confirmation-dialog/) · [NN/g: Error Prevention](https://www.nngroup.com/articles/error-prevention/) · [WCAG 2.2 SC 3.3.2 Labels or Instructions](https://www.w3.org/WAI/WCAG22/Understanding/labels-or-instructions.html) · [SC 3.3.7 Redundant Entry](https://www.w3.org/WAI/WCAG22/Understanding/redundant-entry.html) · [Microsoft globalization guidance](https://learn.microsoft.com/en-us/globalization/)

## Summary
Rules for building settings pages — the configuration surfaces that change how a product behaves for an organisation or an environment, affecting more than the person editing them. Shared configuration is not a personal preference: it needs an explicit save, a confirmable destructive path, and a description that says who it affects. User preferences (settings that affect only the person setting them) follow a lighter pattern and are out of scope here.

## Mandatory Rules

### DO
- Back every settings page with a declared schema, so the same definition drives the form, validation, the API, and the audit record
- Externalise every user-facing string for translation, and verify the page at 200 percent text expansion ([Microsoft globalization](https://learn.microsoft.com/en-us/globalization/))
- Register each settings page in the product's central settings navigation, so every setting is discoverable from one place
- Use the shared settings page wrapper/layout component rather than an app-local layout, so heading level, spacing, and the title divider stay consistent
- Title the page concisely and identically to its entry in the settings navigation
- Follow the title with a description of about two lines saying what the setting controls and who it affects
- Link to the documentation for the setting where documentation exists and covers this page specifically
- Use sentence case for titles, labels, and buttons, and follow the product's content style guide for grammar, punctuation, and tone
- Give every field a visible, persistent label associated programmatically with its control ([W3C: Labels](https://www.w3.org/WAI/tutorials/forms/labels/), SC 3.3.2)
- Open a side sheet or a modal dialog to add or edit a top-level configuration object
- Use a side sheet when the form is long or multi-step; use a modal dialog when it is short
- Require an explicit confirming action for every change — including reordering, inline edits, and sort changes; a shared setting never saves on blur
- Present a collection of configuration objects as a data table (see `datatable.md`)
- Configure the table as contained, at default row density, with horizontal row dividers
- Make the first column the object's identifier (its name)
- Make the last column the row actions column
- Offer Edit and Delete in each row's action menu, each with its conventional icon
- Mark Delete as destructive and confirm it in a dialog naming the object ([NN/g: Confirmation Dialogs](https://www.nngroup.com/articles/confirmation-dialog/))
- Confirm a completed destructive action with a success toast, and report a failed one with an error message that stays on screen
- Open the object's detail in a modal or sheet when a row or its Edit action is activated
- Place the "New item" button at the trailing edge of the table's action area
- Style it as the page's primary action with a leading "+" and a concrete object noun (`+ New connection`, not `+ Add`)
- Confirm successful creation with a toast naming the new object
- Place search at the leading edge of the table's action area
- Put configurable content at the top of the page and non-configurable content (status, usage, related links) below it
- Render an empty state with a mandatory title and a mandatory primary action when no objects exist and the table is the page's only content ([Material: Empty states](https://m2.material.io/design/communication/empty-states.html))
- Pre-fill values the user has already provided elsewhere in the same flow rather than asking again (SC 3.3.7 Redundant Entry)
- Validate on submit and on blur-after-edit, not on every keystroke; associate each error with its field (see `accessibility.md`)

### DON'T
- Put a call to action in the page title bar; page actions belong in the content area below it
- Remove the divider under the page title (unless a tab strip immediately below already provides one)
- Set an unnecessarily small default page size on a settings table
- Save a shared configuration change implicitly — on blur, on toggle, or on drag-release — without an explicit confirm
- Use a switch for a setting that only takes effect after a save; a switch implies immediate effect ([Material 3: Switch](https://m3.material.io/components/switch/guidelines))
- Delete without a confirmation naming the object, or label the confirming button "OK" or "Yes"
- Hide a settings page from a user who lacks write permission; render it read-only instead (see `permissions.md`)
- Use a section heading as the label for the field beneath it
- Ship a hard-coded user-facing string, a concatenated sentence, or a date/number formatted for one locale
- Open a settings form in a full-page navigation when a sheet or dialog would keep the list in context

## Scenarios

### Empty state requirements
- **Title**: mandatory — a direct call to action to create the first object
- **Details**: optional — one sentence of context, or a documentation link
- **Action**: mandatory — a primary button whose label matches the table's own "New item" button exactly
- **Footer**: optional — secondary links to documentation or support material

### Table configuration
- Zebra striping off; horizontal dividers on
- Vertical dividers off unless the data genuinely needs column separation
- Leave the default page size at the component default unless the object count is reliably small
- Sort so the rows needing attention come first (failing before healthy, expiring before valid)
- Use a filter bar of facets for filtering a settings list; a settings list is a bounded set, so it rarely needs the full filter field (see `filterfield.md`)

### Modal vs. sheet
- **Modal dialog**: a short, single-step form — roughly up to six fields
- **Side sheet**: a long form, a multi-step configuration, or a form the user needs to compare against the list behind it
- Either way, follow the [APG modal dialog pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/): focus moved in, focus trapped, Escape closes, focus restored, and a discard confirmation once the form is dirty

---

## Open Questions / Ambiguities

1. **Read-only vs. hidden for unauthorized users**: These rules require rendering a settings page read-only rather than hiding it, which conflicts with a policy of not disclosing that a capability exists. `permissions.md` Scenario 4 covers the disclosure-sensitive case; pick per page and record which applies.

2. **Legacy settings pages**: A product migrating older configuration screens will have pages that predate these rules. Define whether the rules apply on next edit or on a migration schedule, so "non-compliant" and "not yet migrated" are distinguishable in review.

3. **User preferences are out of scope**: Settings affecting only the current user (theme, density, default landing page) follow a lighter pattern with immediate effect and no explicit save. Those need their own guidance; do not apply the explicit-save rule to them by default.

4. **Field-count threshold for modal vs. sheet**: The six-field boundary is a heuristic, not a standard. Where the form's fields are individually complex (a query, a schedule, a credential), prefer a sheet regardless of count.

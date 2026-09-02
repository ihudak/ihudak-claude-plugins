# Connection Experiences

**Sources:** [RFC 6749: OAuth 2.0](https://datatracker.ietf.org/doc/html/rfc6749) · [RFC 8252: OAuth 2.0 for Native Apps](https://datatracker.ietf.org/doc/html/rfc8252) · [RFC 9700: OAuth 2.0 Security Best Current Practice](https://datatracker.ietf.org/doc/html/rfc9700) · [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html) · [Apple HIG: Managing accounts](https://developer.apple.com/design/human-interface-guidelines/managing-accounts) · [Apple HIG: Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy) · [Material 3: Dialogs](https://m3.material.io/components/dialogs/guidelines) · [Material 3: Snackbar](https://m3.material.io/components/snackbar/guidelines) · [Material 2: Empty states](https://m2.material.io/design/communication/empty-states.html) · [APG: Dialog (Modal) pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/) · [NN/g: Wizards](https://www.nngroup.com/articles/wizards/) · [NN/g: Error Message Guidelines](https://www.nngroup.com/articles/error-message-guidelines/)

## Summary
Defines how to build a consistent experience for connecting an application to a third-party system: where connections live in the product, how they are named, how they are created, edited, and deleted, and how credentials are handled. A "connection" is a named, reusable configuration that stores the endpoint and the credential for one external system, so no flow ever asks the user to paste a secret twice.

## Mandatory Rules

### DO
- Keep all connections in one discoverable place in the product's configuration area, and link to it from every flow that consumes a connection
- Group connections by what they do: those that ingest data into the product, and those the product calls out to. Present the two groups under stable, distinct headings
- Give every connection a mandatory, unique, user-supplied display name; treat the name as the connection's identity in every picker that references it
- Store the connection definition as a schema-backed configuration object, so the same definition drives the UI, validation, and the API
- Mark the configuration as a multi-instance, unordered collection — a user may hold many connections to the same vendor
- Scope connection objects to the tenant/organisation, not to the individual user, unless the credential is genuinely personal
- Carry structured metadata on each connection type: vendor, product, and purpose (ingest vs. outbound automation)
- Use the vendor's own terminology for vendor-specific fields (for example, the vendor's own name for a workspace, org, or project) — do not normalise vendor vocabulary into house terms
- Use the product's own terminology for product-side fields
- Name a connection type after the vendor and product it connects to, in the vendor's own capitalisation
- Combine every connection variant for one vendor product under a single connection type rather than shipping one type per auth mechanism
- Prefer OAuth 2.0 authorization-code with PKCE over long-lived API keys where the vendor supports it ([RFC 9700](https://datatracker.ietf.org/doc/html/rfc9700))
- Write secrets to a secret store, never to the configuration record, and never echo them back to the client ([OWASP](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html))
- Mask stored credentials in the edit view and require re-entry to change them; show only a non-reversible hint such as the last four characters
- Offer an explicit "Test connection" action that performs a real round trip and reports the concrete failure (auth, network, permission, TLS), per [NN/g error-message guidance](https://www.nngroup.com/articles/error-message-guidelines/)
- Name an action that a connection exposes concretely and concisely: at most 40 characters, sentence case, verb-first
- Prefix an action name with the service name and a colon where the same verb exists for several services (for example, `Ticket system: List queues`)
- Give every action a one-sentence description with no trailing period
- Show a confirmation before deleting, naming the connection and warning that dependent configurations will break
- Confirm success with a transient status message (toast/snackbar) that names what was created, changed, or deleted

### DON'T
- Hide connections from the configuration area, or make them reachable only from inside the flow that uses them
- Put an ingest connection under the outbound group, or the reverse
- Append "connection" or "connector" to a settings page title — the section already says it
- Name a connection type after a use case or an implementation technology instead of the vendor product
- Use internal jargon, code names, or class names in an action name or description
- Leave an action description blank, or write more than one sentence
- Return, log, or render a stored secret — including in error messages, telemetry, and support bundles
- Accept a credential without validating it; a connection that is saved untested will fail later in a flow with no context
- Close a create/edit dialog on an outside click once the user has entered data
- Report a failure as "Something went wrong" with no cause and no next step

## Scenarios

### Empty state (no connections exist)
- Render an empty state with a title, one sentence of context, and a primary call to action to create the first connection ([Material: Empty states](https://m2.material.io/design/communication/empty-states.html))
- Link to the setup documentation from the empty-state body or footer
- Do not render an empty table with headers and no rows as the empty state

### Creating a connection
- Use a modal dialog for single-step creation; use a stepped flow only where the vendor requires a genuine multi-stage handshake ([NN/g: Wizards](https://www.nngroup.com/articles/wizards/))
- Size the dialog to the content: medium for a handful of fields
- Implement the dialog as the [APG modal dialog pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/) — focus moved in on open, focus trapped, Escape closes, focus restored to the trigger on close
- Include an inline message area for status, permission, and security information
- If no field has been touched, the dialog may close without confirmation
- If any field has been touched: an outside click must not close it; Cancel or the close control raises a discard confirmation
- Save validates, creates, and closes; on validation failure keep the dialog open, keep the user's input, and mark the failing fields (see `accessibility.md` on `aria-invalid` and `aria-describedby`)
- Confirm with a success toast naming the new connection

### Editing a connection
- List connections in a data table (see `datatable.md`), name column first, actions column last
- Place search at the leading edge of the table's action area and the primary "New connection" button at the trailing edge
- Make rows interactive, opening the edit view; expose Edit and Delete in the row action menu
- Title the edit dialog "Edit connection"
- Place the destructive action (Delete) at the leading edge of the dialog footer, visually de-emphasised; place Cancel and Save at the trailing edge with Save as the primary action
- With unsaved changes: an outside click must not close the dialog; Cancel or close raises a discard confirmation
- Confirm with a success toast

### Deleting a connection
- Raise a small confirmation dialog titled with the target: `Delete "<connection name>"?`
- State that deletion is permanent and that dependent configurations should be reviewed first
- Label the confirming action with the verb and object (`Delete connection`), never "OK" or "Yes"
- Remove the row on success and confirm with a toast

### Insufficient permissions
- Follow `permissions.md` for every case below
- Surface a single message describing the missing permissions at the top of the connections view
- Render the create action disabled with `aria-disabled` and a tooltip naming the missing permission, rather than hiding it
- Replace "Edit" with "View" where the user may read but not change
- Disable "Delete" with a tooltip naming the missing permission
- In the edit dialog, show the same message and disable Save and Delete with tooltips

---

## Open Questions / Ambiguities

1. **Scope of a connection object**: The rule to scope connections to the tenant has a real exception for personal credentials (a user's own account at a vendor). No public source draws that line; a product must decide per connection type and record the decision in the schema metadata.

2. **Validation depth**: "Test connection" is required, but how deep the test goes — auth only, or auth plus a scope probe — is unspecified. A shallow test that passes and a later flow that fails on scope is a known failure mode worth an explicit decision.

3. **Pagination and scale**: No guidance is given for tenants holding hundreds of connections. Apply `datatable.md`'s rules for a data-heavy table (server-side paging, sortable columns, filter field) rather than rendering an unbounded list.

4. **Credential rotation**: The rules cover creating and editing a credential but not scheduled rotation or expiry warnings. [RFC 9700](https://datatracker.ietf.org/doc/html/rfc9700) recommends short-lived tokens with refresh; a product using long-lived API keys should define its own expiry-warning behaviour.

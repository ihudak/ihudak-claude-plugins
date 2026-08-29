# Missing Permissions

**Sources:** [OWASP Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html) · [OWASP Error Handling Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Error_Handling_Cheat_Sheet.html) · [Apple HIG: Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy) · [Apple HIG: Accessing private data](https://developer.apple.com/design/human-interface-guidelines/accessing-private-data) · [Material 2: Empty states](https://m2.material.io/design/communication/empty-states.html) · [APG: Alert pattern](https://www.w3.org/WAI/ARIA/apg/patterns/alert/) · [NN/g: Error Message Guidelines](https://www.nngroup.com/articles/error-message-guidelines/) · [NN/g: Visibility of System Status](https://www.nngroup.com/articles/visibility-system-status/) · [WCAG 2.2 SC 4.1.3 Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html) · [SC 3.3.1 Error Identification](https://www.w3.org/WAI/WCAG22/Understanding/error-identification.html)

## Summary
Best practice for telling a user that they cannot do something because of an authorization decision. The design tension is real and worth naming: usability wants the user to know exactly what is missing so they can ask for it, while security wants the interface to disclose nothing about the policy that produced the decision. These rules resolve it by naming the **permission the user needs** — which they can request — while never revealing the **policy structure or the existence of data** they are not entitled to know about ([OWASP: Authorization](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html)).

## Mandatory Rules

### DO
- Put the message next to the element the user cannot use, not in a separate log or a global banner
- Keep the control visible and disabled rather than hidden, so the user learns the capability exists and what it needs
- Name the missing permissions concretely, in a condensed, copyable code block
- Include everything a support request needs, in one copyable block: message, missing permissions, environment or tenant identifier, application name, user identifier, and timestamp
- Break the copyable block onto one line per field so it stays legible when pasted
- Mark a disabled control with `aria-disabled="true"` (rather than the `disabled` attribute) where it must remain focusable and its tooltip reachable — a `disabled` control is skipped by keyboard and its explanation becomes unreachable
- Give the disabled control an accessible description naming the missing permission, so the explanation is announced and not only shown on hover
- Use a hover/focus overlay with a "View details" button for a blocked action that is not critical to the page's purpose
- Open a dialog with the copyable block when the user activates "View details"
- Merge several missing permissions on one page into a single message region
- Announce a permission failure that arrives asynchronously through a live region (SC 4.1.3)
- State what the user should do next: request the named permission from a workspace admin, or switch to a context where they hold it ([NN/g: Error Message Guidelines](https://www.nngroup.com/articles/error-message-guidelines/))
- Enforce every permission on the server; treat the UI's disabled state as a courtesy, never as the control

### DON'T
- Reveal the policy that produced the decision — its conditions, its boundaries, or which rule matched
- Hide a control that the user could hold a permission for; hiding it makes the capability undiscoverable and un-requestable
- Leave the user to guess which permission is missing
- Interrupt with a modal or an alert for a non-critical blocked action
- Render a control as enabled and only reveal the permission failure after the user has acted
- Put a call-to-action button inside a tooltip — a tooltip is not interactive and cannot be reached by keyboard or touch
- Show several message regions for several missing permissions on the same page
- Disclose that data exists but is withheld by a conditional access rule — say there is nothing to show
- Use a read-only badge to represent an authorization outcome; reserve it for object-level sharing states
- Echo the raw authorization error, stack trace, or policy identifier into the UI ([OWASP: Error Handling](https://cheatsheetseries.owasp.org/cheatsheets/Error_Handling_Cheat_Sheet.html))

## Scenarios

### Scenario 1: Complete access denied (high severity)
**When:** The user lacks the permissions for the application's core data or core action, so the app cannot deliver its purpose.

**Required behaviour:**
- Render a full-page empty state: `You'll need additional permissions to use <app name>`
- Pair it with a copyable block:
  ```
  Message: You'll need additional permissions to use <app name>
  Missing permissions: <PERMISSION-1>, <PERMISSION-2>
  Environment: <ENVIRONMENT_ID>
  App name: <APP_NAME>
  User: <USER_IDENTIFIER>
  Time: <ISO-8601 TIMESTAMP>
  ```
- Offer one forward action: a link to the access-request process, or to a sample/demo environment where the capability can be evaluated

### Scenario 2: A single action is denied (low severity)
**When:** The user is blocked from one non-critical action — a form control such as a text input, select, radio, checkbox, or switch.

**Required behaviour:**
- Render the control disabled with `aria-disabled="true"` and a `not-allowed` cursor
- Show the explanation on hover and on keyboard focus — never on hover alone
- Message: `You'll need additional permissions to <action>`
- "View details" opens a dialog holding the copyable block

### Scenario 3: An important action is denied (optional nudge)
**When:** The user is blocked from an action that is important but not core.

**Required behaviour:**
- Combine a page-level message region with the per-control overlay from Scenario 2
- Keep the message region non-dismissable while the condition holds — it describes a state, not an event
- Do not use this treatment for a permanent restriction; a permanent restriction is Scenario 2

### Scenario 4: Conditional access (data exists but is filtered)
**When:** Records exist but a conditional access rule removes them from this user's result set.

**Required behaviour:**
- Render the ordinary empty state: `No <entities> available`
- Do not indicate that anything was filtered, how much, or by what rule
- This is the one case where the interface deliberately tells the user less than it knows, because acknowledging the filter leaks the existence of the data

### Special case: read-only state
**When:** The user has view-only access to an object through object-level sharing (a shared document, dashboard, or notebook).

**Required behaviour:**
- Render a read-only badge on the object
- Do not use the read-only badge to represent a role- or policy-level authorization outcome — that is Scenario 1, 2, or 3

---

## Open Questions / Ambiguities

1. **Partial access is undefined**: No guidance covers a page where some regions are permitted and others are not. As a working rule, apply Scenario 2 per blocked control and raise Scenario 1 only when nothing on the page is usable.

2. **Failure of the permission check itself**: The scenarios assume the check returns a decision. A check that times out or errors is not a denial and should not be presented as one — render a retryable error state naming the check as the failure, per [NN/g's error-message guidance](https://www.nngroup.com/articles/error-message-guidelines/).

3. **The forward action needs a destination**: Scenario 1 requires an action, but its target — an access-request workflow, an admin contact, a trial environment — is product-specific. Ship a configured destination, not a dead button.

4. **Permission naming leaks vocabulary**: Naming the missing permission requires the permission identifier to be meaningful to a user who does not administer the system. Where identifiers are opaque, pair the identifier with a human-readable description in the copyable block.

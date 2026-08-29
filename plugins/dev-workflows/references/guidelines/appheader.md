# App Header (Top App Bar)

**Sources:** [Material 3: Top app bar](https://m3.material.io/components/top-app-bar/guidelines) · [Material 3: Tabs](https://m3.material.io/components/tabs/guidelines) · [Material 3: Menus](https://m3.material.io/components/menus/guidelines) · [Apple HIG: Navigation bars](https://developer.apple.com/design/human-interface-guidelines/navigation-bars) · [Apple HIG: Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars) · [Apple HIG: Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars) · [Fluent 2](https://fluent2.microsoft.design/) · [APG: Tabs pattern](https://www.w3.org/WAI/ARIA/apg/patterns/tabs/) · [APG: Menu Button pattern](https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/) · [WCAG 2.2 SC 3.2.3 Consistent Navigation](https://www.w3.org/WAI/WCAG22/Understanding/consistent-navigation.html) · [WCAG 2.2 SC 3.2.6 Consistent Help](https://www.w3.org/WAI/WCAG22/Understanding/consistent-help.html)

## Summary
Defines the mandatory shape of the app header — the persistent bar at the top of an application that carries first-level navigation. Material calls it a **top app bar**, Apple splits the same responsibilities across the **navigation bar** and **toolbar**, and Fluent calls it the **header**. Whatever the platform name, it holds the app identity, the app's tabs (if any), and the app-level menus: settings where the app has them, and help, always. Its contents and their order stay identical on every page of the app, which is what WCAG SC 3.2.3 and SC 3.2.6 require.

## Mandatory Rules

### DO
- Render the app header on every page of the app with identical contents and identical ordering (SC 3.2.3 Consistent Navigation)
- Include the app identity (logo and/or app name), the app's tabs where it has more than one top-level area, and the app-level menus
- Include a help entry point in every app, in the same relative position on every page (SC 3.2.6 Consistent Help)
- Make the app identity a link to the app's home destination — the landing page for a single-area app, the first tab for a tabbed app
- Place app-level menus at the trailing edge of the bar (right in LTR, left in RTL), with help outermost and settings inboard of it
- Give every icon-only control in the header an accessible name and a tooltip carrying identical text (see `accessibility.md`)
- Keep hover, focus-visible, and active states on every header control
- Implement the tab set as the [APG tabs pattern](https://www.w3.org/WAI/ARIA/apg/patterns/tabs/): arrow-key traversal within the set, a single tab stop into it, and `aria-selected` on the active tab
- Implement each header menu as the [APG menu button pattern](https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/): `aria-expanded` on the trigger, arrow-key navigation, Escape to close and return focus
- Show the active state on the selected tab, and mark the current destination with `aria-current` where tabs map to routes
- Give apps with user-configurable settings a visible settings entry point in the header
- Route the settings entry point to the specific section that configures this app, not to a generic settings root
- Style app-wide action items in the header as low-emphasis (neutral / tertiary / text-button) so they do not compete with in-page primary actions
- Mirror the header layout under right-to-left locales ([Apple HIG: Right to left](https://developer.apple.com/design/human-interface-guidelines/right-to-left))
- Collapse the header responsively at narrow widths without losing any entry point — overflow, do not drop (SC 1.4.10 Reflow)

### DON'T
- Render the app identity as one more tab in the tab set
- Reorder, re-icon, or re-label the standard header entries per page or per app
- Add visible text labels to standard icon-only action items — the tooltip and accessible name carry the label
- Suppress hover or focus states on header controls to "clean up" the bar
- Hand-build a bespoke help menu when the design system ships one
- Combine prefix and suffix icons on the same menu item
- Exceed two app-wide action items in the header; a third belongs in an overflow menu or on the page
- Render two help entry points (for example, one in the header and one duplicated in a settings menu)
- Use the primary or accent button style for a header action item
- Put a page-scoped action in the app header — the header is app-scoped only

## Scenarios

### Scenario 1: App without tabs
Use when the app has one primary flow, one use case, or one way to explore its data.
- Required parts: app identity, app-level menus (including help)
- Clicking the app identity returns the user to the app's starting page
- Material equivalent: a small or centre-aligned top app bar; Apple equivalent: a navigation bar with no segmented/tab control

### Scenario 2: App with two or more tabs
Use when the app has several top-level areas, distinct personas, or distinct access levels.
- Required parts: app identity, tab set, app-level menus
- Clicking the app identity selects the first tab
- Every tab is keyboard-reachable, shows an active state, and exposes `aria-selected`
- Beyond roughly five top-level areas, prefer a navigation rail or drawer to a tab set ([Material 3: Navigation drawer](https://m3.material.io/components/navigation-drawer/guidelines))

### Scenario 3: App with app-wide actions (recommended, not enforced)
Use when one or two actions must remain reachable from every page of the app.
- **Note**: This scenario is a recommendation; it is not gated in review
- Parts: app identity, tab set (if applicable), one or two action items, app-level menus
- Hard cap of two action items; further actions go into an overflow menu

### Help menu contents
Where the design system does not prescribe the entries, the conventional set is: what's new, getting started, documentation, keyboard shortcuts, share feedback, and about this app.
- Hide an entry that has no destination rather than rendering it disabled or dead
- Keep the entry order identical across every app in a suite (SC 3.2.6 Consistent Help)

---

## Open Questions / Ambiguities

1. **Help menu contents are conventional, not standardised**: No public design system fixes the entries of an application help menu. The set listed above is the common denominator; a product should pin its own list in a shared component so it cannot drift per app.

2. **No settings destination**: The rules do not say what to do when an app has settings but the product has no central settings destination to route to. Render the settings entry inline (a panel or sheet owned by the app) rather than dropping the entry point.

3. **Tab-count threshold is soft**: The advice to switch from tabs to a rail or drawer past roughly five areas comes from Material's navigation guidance and is not an absolute. Treat it as a review prompt, not a gate.

4. **Component-version compatibility**: Where the design system's header component has evolved, older major versions may not expose the required entry points. Record the minimum version the rules assume, so "non-compliant" and "on an old version" are distinguishable in review.

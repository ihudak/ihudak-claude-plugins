# Ready-made Dashboards

**Sources:** [Material 2: Data visualization](https://m2.material.io/design/communication/data-visualization.html) · [Material 2: Responsive layout grid](https://m2.material.io/design/layout/responsive-layout-grid.html) · [Apple HIG: Charts](https://developer.apple.com/design/human-interface-guidelines/charts) · [Apple HIG: Color](https://developer.apple.com/design/human-interface-guidelines/color) · [Material 3: Color roles](https://m3.material.io/styles/color/roles) · [WCAG 2.2 SC 1.4.1 Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html) · [SC 1.4.3 Contrast (Minimum)](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) · [SC 1.4.11 Non-text Contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html) · [SC 1.4.10 Reflow](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html) · [NN/g: Dashboards and preattentive attributes](https://www.nngroup.com/articles/dashboards-preattentive/) · [NN/g: Visibility of System Status](https://www.nngroup.com/articles/visibility-system-status/)

## Summary
Quality standards for **ready-made dashboards** — dashboards a product ships to its users rather than dashboards a user builds. A ready-made dashboard must render correctly with no configuration on first open, answer a stated question above the fold, and be readable without colour vision. These rules are mandatory for any dashboard published to a sample environment or shipped in a product.

## Mandatory Rules

### DO
- Render with no errors and no warnings in the default configuration, on a fresh account, at the default time range
- Set every default explicitly: data source, entity references, query text, time range, and any environment or cluster selector
- Return both the stable identifier field and the human-readable name field for every entity a tile links from, so navigation from the tile resolves
- Give every variable a default that produces data, at least two selectable options, and at least one tile that references it
- Name variables and their options in plain product vocabulary, in sentence case (`Yes`, `No` — not `YES`, `NO`, not `y`/`n`)
- Open with an introduction tile carrying an H3 (`###`) title of at most 50 characters
- Follow the title with a value statement of at most 300 characters in the default body style, saying what question the dashboard answers
- Include one or two links to onboarding or getting-started material in the introduction tile
- Keep the introduction tile's content visible without scrolling inside the tile
- Use sentence case for every tile title and section heading
- Put the most decision-relevant tiles above the fold — assume a usable viewport height of 768–1080 CSS pixels
- Pick colours that pass WCAG contrast against their own background: 4.5:1 for text (SC 1.4.3), 3:1 for chart strokes, thresholds, and other meaningful graphics (SC 1.4.11)
- Take threshold and status colours from the design system's semantic colour roles (error / warning / success) rather than hand-picked hex values, so themes and dark mode follow ([Material 3: Color roles](https://m3.material.io/styles/color/roles), [Apple HIG: Color](https://developer.apple.com/design/human-interface-guidelines/color))
- Pair every colour-coded state with a label, a shape, or a value, so the dashboard reads without colour (SC 1.4.1)
- Verify contrast of value text rendered over a colour-coded background, in both light and dark themes
- Use a line or area chart for change over time, a bar chart for comparison across categories, and a table for detail and lookup ([Material: Data visualization](https://m2.material.io/design/communication/data-visualization.html))
- Fill the grid without leaving gaps between tiles; align tiles to the layout grid ([Material: Responsive layout grid](https://m2.material.io/design/layout/responsive-layout-grid.html))
- Keep the layout usable down to a narrow breakpoint (around 650 CSS pixels) without two-dimensional scrolling (SC 1.4.10)
- Cap a row at 6 single-value tiles, or 4 heavy tiles (chart, table, or long text)
- Allow at most one tile per row that requires horizontal scrolling to read
- Use H3 (`###`) for section titles and H5 (`#####`) for subtitles, with no skipped levels
- Separate a new section from the one above it with a single full-width spacing tile
- Describe a single tile with the tile's own description affordance, not with an adjacent text tile
- Comment non-obvious query code with what it returns and why that filter or aggregation is there
- Close with a footer holding deeper explanation, documentation links, and learning resources
- Show an explicit loading state per tile and an explicit "no data" state distinguishable from an error (NN/g: [Visibility of System Status](https://www.nngroup.com/articles/visibility-system-status/))

### DON'T
- Ship a dashboard whose first render requires the user to fix a variable, a time range, or a data source before anything appears
- Open in an error state, a "No options available" state, or a "Select an option to continue" state
- Use internal jargon, code names, or query fragments as a tile title
- Omit the introduction tile or the getting-started links
- Title a dashboard or tile generically ("Overview", "Technology overview", "Metrics")
- Repeat the dashboard name in a tile title
- Leave empty space or low-value tiles above the fold
- Fill the whole first screen with a single oversized tile or a single oversized number
- Use a colour pair that fails the WCAG contrast requirement for its role, in either theme
- Encode a state only in colour — red and green bars with no labels are unreadable to roughly one in twelve male users
- Leave layout gaps or misaligned tile edges
- Put more than 6 elements in one row
- Use a free-text tile to caption the tile next to it
- Ship a blank dashboard with no guidance for a user who has not onboarded the data yet
- Reproduce documentation on the dashboard — link to it

## Scenarios

### Sample and demo environments
- Verify the dashboard against an account with only the permissions a new user is granted; a dashboard that renders for an admin and errors for everyone else is not ready
- Check every tile after a permission-scoped render, not just the first screen

### Variable naming conventions
- Use the platform's own "all values" token for the unfiltered case rather than inventing a sentinel string
- Capitalise option labels as sentence case (`Yes`, `No`); reserve all-caps for acronyms

### Chart selection
- Trend over time → line or area chart
- Comparison across a small category set → bar chart
- Part-to-whole with fewer than about five parts → stacked bar; avoid pie charts for more than about five slices ([Apple HIG: Charts](https://developer.apple.com/design/human-interface-guidelines/charts))
- Exact values, many dimensions, or lookup → table
- Single headline number with a trend → single-value tile with a sparkline

---

## Open Questions / Ambiguities

1. **Grid column widths are undefined**: The rules assume a layout grid but do not fix column counts or pixel widths. [Material's responsive layout grid](https://m2.material.io/design/layout/responsive-layout-grid.html) gives 4/8/12 columns by breakpoint; adopt those unless the product's own grid says otherwise.

2. **Fold height is a range, not a target**: 768–1080 CSS pixels covers most desktop viewports but does not name a design target. Design to the lower bound (768) so the dashboard is correct on the smallest common viewport.

3. **Maximum dashboard length is unspecified**: No guidance limits scroll depth. As a working rule, a ready-made dashboard that needs more than about three screens is two dashboards.

4. **"Information density" is subjective**: References to medium information density carry no metric. Treat tile-count-per-row caps as the enforceable proxy and density as a review discussion.

5. **Theme coverage**: Contrast must hold in every theme the product ships. Where a dashboard hard-codes a colour, it will pass in one theme and fail in the other; that is why semantic colour roles are mandatory above.

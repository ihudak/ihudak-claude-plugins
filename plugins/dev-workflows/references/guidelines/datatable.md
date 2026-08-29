# Data Table

**Sources:** [APG: Grid (interactive tabular data) pattern](https://www.w3.org/WAI/ARIA/apg/patterns/grid/) · [APG: Table pattern](https://www.w3.org/WAI/ARIA/apg/patterns/table/) · [W3C WAI Tables Tutorial](https://www.w3.org/WAI/tutorials/tables/) · [Apple HIG: Lists and tables](https://developer.apple.com/design/human-interface-guidelines/lists-and-tables) · [Material 3: Lists](https://m3.material.io/components/lists/guidelines) · [Fluent 2](https://fluent2.microsoft.design/) · [NN/g: Data Tables](https://www.nngroup.com/articles/data-tables/) · [WCAG 2.2 SC 2.5.8 Target Size (Minimum)](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html) · [SC 2.4.11 Focus Not Obscured](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html) · [SC 4.1.3 Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html)

## Summary
Specifies the interaction pattern for a **data table** — the component used for data-heavy analysis and for structured lists of configured objects. Actions live at one of five scopes, and the scope decides where the control goes: table, column, row, selection, and cell. Getting the scope wrong is the single most common defect in table implementations, because it puts a row action in a cell menu or a cell action in the table toolbar, and users stop being able to predict what a control will affect.

Two table shapes appear throughout these rules:
- **Data-heavy table** — many rows and columns, read for analysis, scanned and exported. Needs the full feature set below.
- **Structured list** — a bounded set of configured objects (connections, rules, users), read for management. Needs search, sort, and row actions; the analysis features are optional.

## Mandatory Rules

### DO
- Use the design system's data table component rather than a hand-rolled `<table>`; a bespoke table almost never carries the keyboard model
- Follow the [APG grid pattern](https://www.w3.org/WAI/ARIA/apg/patterns/grid/) for an interactive table: one tab stop into the grid, arrow keys to move between cells, `Home`/`End` for row extremes, `Ctrl+Home`/`Ctrl+End` for the grid extremes
- Follow the [APG table pattern](https://www.w3.org/WAI/ARIA/apg/patterns/table/) for a static, non-interactive table
- Mark up header cells as header cells with an explicit scope, so a screen reader announces the column name with each value ([W3C tables tutorial](https://www.w3.org/WAI/tutorials/tables/))
- Use the component's built-in features, slots, and mechanisms instead of re-implementing them alongside
- Put table-scoped controls (search/filter, line wrap, column settings, density, export) in the table's **action area** — the toolbar above the table
- Enable line wrap, column settings, and data export on a data-heavy table
- Provide a search or filter control in the table action area for a structured list (see `filterfield.md` for which filter control to use)
- Enable column sorting and column resizing on every data table
- Enable column reordering, per-column line wrap, and column visibility on a data-heavy table
- Put column-scoped controls in the **column actions menu** on the column header
- Keep a stable order in the column actions menu: custom column actions first, then column order, then line wrap, then hide column
- Announce the sort state on the header cell with `aria-sort`, and re-announce the row count after sort or filter through a live region (SC 4.1.3)
- Use row click for **in-context** disclosure only: a detail panel, a side sheet, a drawer, or a modal
- Enable row interactivity on a data-heavy table even where there is no primary action, so the active row is highlighted and keyboard focus is visible
- Put row-scoped actions in the **row actions** cell, as the last column
- Put actions that operate on the current selection in a **bulk actions** area that appears when the selection is non-empty, and state the selected count in it
- Put cell-scoped actions in the **cell actions** affordance
- Offer copy-cell-value as the first cell action on a data-heavy table
- Use a link component for navigation that leaves the current context for another page or another product
- Render an explicit loading state (skeleton rows or a progress indicator) and an explicit empty state; distinguish "no rows match the filter" from "no data exists yet"
- Keep every interactive target in the table at least 24 by 24 CSS pixels, or give it equivalent spacing (SC 2.5.8)
- Keep a focused row or cell fully visible under any sticky header, sticky footer, or bulk-actions bar (SC 2.4.11)
- Paginate or virtualise beyond the point where the browser stalls, and keep the total row count visible either way

### DON'T
- Override or replace the component's built-in mouse, touch, or keyboard interaction with a bespoke equivalent
- Move, relabel, or hide the component's built-in actions to make room for custom ones
- Use row click to navigate to a different page — a user who clicks a row expects to stay
- Use a link for in-context disclosure (detail panel, modal, overlay) — a link promises navigation
- Expose a row-scoped action (delete row, duplicate row) as a cell action
- Put a table-scoped action inside a row menu, or a row action in the table toolbar
- Nest an interactive control inside a cell without making it reachable by the grid's own keyboard model
- Trap arrow keys inside an editable cell with no documented way out (`Escape` must return to cell navigation)
- Sort or re-order rows underneath the user while they are reading, without an explicit action
- Rely on colour alone for a row state such as error, stale, or selected (see `accessibility.md`)
- Hide the selection count when a bulk action is available
- Ship an unbounded table that renders every row of an unbounded result set

## Scenarios

### Scenario 1: Table interactions
Actions affecting the whole table — line wrap, column settings, density, export, and custom search or filter.
- Custom controls go in the table action area, to the leading edge for search/filter and the trailing edge for the primary action

### Scenario 2: Column interactions
Actions affecting one column — sort, resize, reorder, line wrap, visibility.
- Custom column actions go in the column actions menu, above the built-in entries, in the prescribed order

### Scenario 3: Interactive rows (row click)
Row click discloses information in context — a detail panel, a side sheet, or a modal.
- A data-heavy table enables row interactivity even with no primary action, for row highlighting and focus
- The row's accessible name identifies the row (its identifier column), not "row 4"

### Scenario 4: Row interactions
Actions affecting one row — edit, duplicate, delete.
- Row actions live in the last column; beyond two actions use an overflow menu
- A destructive row action is styled as destructive and confirms before executing

### Scenario 5: Selected-row interactions
Actions affecting the current multi-row selection.
- The bulk actions area appears only when the selection is non-empty and names the count ("3 selected")
- Clearing the selection is always available from the same area
- A select-all control states its scope explicitly: page vs. all matching rows

### Scenario 6: Cell interactions
Actions affecting a single cell value.
- Cell actions live in the cell's own affordance
- On a data-heavy table, copy-value is the first cell action

### Scenario 7: Interactive content inside cells
Clickable content rendered inside a cell.
- Use a link only for a context switch to another page
- Any other in-cell control is a button, and is part of the grid's keyboard model

---

## Open Questions / Ambiguities

1. **Data-heavy vs. structured list has no numeric threshold**: The split drives which features are mandatory, but no public source fixes a row or column count. As a working rule: a table a user scans and exports is data-heavy; a table a user manages a bounded set of objects in is a structured list. Record the classification in the review rather than arguing it per rule.

2. **Editable cells are out of scope**: These rules cover reading and acting on rows, not inline editing. The [APG grid pattern](https://www.w3.org/WAI/ARIA/apg/patterns/grid/) covers the keyboard model for editable cells; the save/validate/cancel semantics need their own decision.

3. **Pagination vs. virtualisation is unspecified**: Both satisfy the rules. Virtualisation preserves scroll position and `Ctrl+End`; pagination gives stable, linkable positions and is easier to make accessible. Pick one per table and be consistent within a product.

4. **Column-menu ordering assumes a fixed built-in set**: The prescribed order (custom, column order, line wrap, hide column) assumes those built-ins exist. Where the component ships a different set, keep custom actions first and the built-ins in the component's own order.

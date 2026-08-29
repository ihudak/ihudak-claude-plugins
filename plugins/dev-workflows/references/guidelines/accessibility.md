# Accessibility (WCAG 2.2 AA)

**Sources:** [WCAG 2.2](https://www.w3.org/TR/WCAG22/) · [WAI-ARIA Authoring Practices Guide](https://www.w3.org/WAI/ARIA/apg/) · [APG: Accessible Names and Descriptions](https://www.w3.org/WAI/ARIA/apg/practices/names-and-descriptions/) · [W3C WAI Images Tutorial](https://www.w3.org/WAI/tutorials/images/) · [W3C WAI Forms: Labels](https://www.w3.org/WAI/tutorials/forms/labels/) · [Material 3: Accessible design](https://m3.material.io/foundations/accessible-design/overview) · [Apple HIG: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) · [Section 508](https://www.section508.gov/) · [EN 301 549 v3.2.1](https://www.etsi.org/deliver/etsi_en/301500_301599/301549/03.02.01_60/en_301549v030201p.pdf)

## Summary
Targets WCAG 2.2 Level AA, the conformance level referenced by Section 508 (via the ICT Refresh) and by EN 301 549 for public-sector procurement in the EU. This file is the curated, checkable subset that reviews actually catch violations against: accessible names, state announcement, colour independence, form labelling, and image alternatives. Where a design system component already implements a pattern correctly, prefer it over a hand-rolled equivalent — every design system cited above ships components pre-wired for these criteria.

## Mandatory Rules

### DO
- Prefer the design system's own components over hand-rolled equivalents; they carry the roles, states, and focus handling already
- For a custom widget, implement a named pattern from the [ARIA Authoring Practices Guide](https://www.w3.org/WAI/ARIA/apg/) rather than inventing keyboard and role behaviour
- Give every interactive control a non-empty accessible name (SC 4.1.2 Name, Role, Value)
- Make the accessible name of a control start with its visible label text, so speech-input users can address it (SC 2.5.3 Label in Name)
- Announce state changes to assistive technology — `aria-expanded`, `aria-selected`, `aria-checked`, `aria-current` — and announce the control's new state before moving focus into the dialog or panel it opened
- Convey status with a text label or an icon in addition to colour (SC 1.4.1 Use of Color)
- Give every input a visible, persistent label that stays on screen while the user types (SC 3.3.2 Labels or Instructions)
- Associate the label programmatically: `<label for>`, wrapping `<label>`, or `aria-labelledby` pointing at visible text
- Provide `alt` text for informative images that conveys the same information the image conveys (SC 1.1.1 Non-text Content)
- Keep text as text; do not render informative copy as an image (SC 1.4.5 Images of Text)
- Maintain 4.5:1 contrast for body text and 3:1 for large text, UI component boundaries, and graphical objects that carry meaning (SC 1.4.3, SC 1.4.11)
- Keep a visible focus indicator on every keyboard-focusable element, meeting the 3:1 contrast and minimum-area requirements (SC 2.4.7, SC 2.4.11 Focus Not Obscured, SC 2.4.13 Focus Appearance)
- Make every pointer-operable action reachable from the keyboard with no keyboard trap (SC 2.1.1, SC 2.1.2)
- Provide a pointer target of at least 24 by 24 CSS pixels, or adequate spacing around a smaller one (SC 2.5.8 Target Size (Minimum))
- Offer a single-pointer alternative to any drag operation (SC 2.5.7 Dragging Movements)
- Announce asynchronous results — validation summaries, save confirmations, result counts — through a live region (SC 4.1.3 Status Messages)
- Keep the same component labelled the same way everywhere it appears (SC 3.2.4 Consistent Identification)
- Support reflow to a 320 CSS pixel viewport width without two-dimensional scrolling (SC 1.4.10 Reflow)

### DON'T
- Let the tooltip text and the `aria-label` of an icon-only control differ — a speech-input user says what they see
- Add `alt` text or an accessible name to an icon that sits beside text already naming the control; mark it `aria-hidden="true"` instead
- Ship a control whose accessible name is empty, is the icon file name, or is the word "button"
- Use vague link text such as "Click here", "More", "Read more", or "Learn more" as the whole accessible name (SC 2.4.4 Link Purpose)
- Move focus into a dialog before the triggering control's state has been updated
- Rely on colour alone — red/green status dots, coloured chart series with no direct labels or patterns
- Use placeholder text as the only label; it disappears on first keystroke and typically fails contrast (SC 3.3.2)
- Add `alt` text to a decorative image; use `alt=""` so screen readers skip it
- Convey an instruction, a threshold, or a value only inside a screenshot or diagram
- Trigger navigation, submission, or a context change purely on focus or on value change without warning (SC 3.2.1, SC 3.2.2)
- Remove `:focus-visible` styling to "clean up" the design
- Suppress a real `<button>`/`<a>` in favour of a `<div>` with an `onClick` handler and no role, `tabindex`, or key handling

## Key Requirements by Category

### Accessible Controls

**Icon-only controls:**
- Mark the SVG `aria-hidden="true"` (and `focusable="false"` for legacy engines); do not give it `role="img"` when the parent control carries the name
- Put the name on the control itself: `aria-label`, or a visually hidden text node
- Make the tooltip text identical to the accessible name
- Add a tooltip unless the icon is a platform convention the user already knows from every other app (close, search, back, overflow); when in doubt, add it

**Text + icon controls:**
- Mark the icon `aria-hidden="true"`
- Let the visible text be the accessible name; do not add an `aria-label` that differs from it
- Do not give the icon its own `alt`/name — it would be announced twice

**Text-only controls:**
- Let the visible text be the accessible name; leave `aria-label` unset
- Write link text that identifies the destination on its own, out of context

**State announcement:**
- Disclosure controls carry `aria-expanded` on the control (not on the panel) — see [APG: Disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/)
- Selection state uses `aria-selected` (tabs, grid cells) or `aria-checked` (checkbox, switch, radio)
- The current page or step in a navigation set carries `aria-current`
- Update state before moving focus, so the change is in the accessibility tree when the new context is announced

### Accessible Statuses
- Pair every status colour with a text label, an icon with a distinct shape, or both
- Add an icon only when the adjacent text does not already name the status — otherwise it is redundant announcement noise
- Distinguish status icons by shape, not by colour alone: a filled circle for one state and a filled circle in another colour for a second state is a failure
- Chart series and threshold bands need direct labels, patterns, or shapes as well as colour

### Accessible Form Fields

**Search and filter inputs:**
- Use the platform's search input (a persistent leading search affordance) rather than a bare text input styled to look like one
- Give a filter input a leading filter affordance and a persistent visible label
- Never rely on the placeholder as the only label

**In-place rename (click-to-rename) fields:**
- Provide a second route to the same action — an overflow/context menu entry — because click-to-rename is not discoverable and is hard to reach by keyboard
- Name the control so the target is unambiguous, e.g. `Rename dashboard: Quarterly revenue`

**Generic input fields:**
- Every input needs its own associated label; a section heading is not a label
- Required, format, and constraint information belongs in programmatically associated help text (`aria-describedby`), not only in the placeholder
- Error text is associated with the field via `aria-describedby` and the field is marked `aria-invalid="true"` (SC 3.3.1 Error Identification)

**Placeholder text:**
- Placeholder text is a hint, never a label — the label stays visible while the field has content
- If a placeholder is used, it must meet the 4.5:1 text contrast requirement like any other text
- Fields that commonly carry a format hint: date/time pickers, numeric inputs, password inputs, selects, code editors, filter fields, text areas, and text inputs — give each a real label plus a format hint where the expected input is not obvious

### Multimedia

**Images:**
- Classify every image as decorative or informative before writing markup
- Informative image → `alt` text conveying the same information; complex image (chart, diagram) → short `alt` plus a long description nearby or linked
- Decorative image → `alt=""` (or CSS background), never a missing `alt` attribute
- Never use an image as the only carrier of an instruction, a value, or a threshold
- Render informative text as HTML so it can be zoomed, restyled, translated, and read aloud

---

## Open Questions / Ambiguities

1. **"Universally understood" icons are undefined**: The rule to add a tooltip unless the icon is a platform convention has no objective test. [NN/g's icon usability research](https://www.nngroup.com/articles/icon-usability/) finds that very few icons are universally recognised without a text label; treat the exemption as narrow and test with real users when it matters.

2. **State-announcement timing is implementation-specific**: "Announce state before moving focus" is achievable in most frameworks but the exact ordering depends on how the framework batches DOM updates. Verify with a screen reader rather than by code reading.

3. **Icon-as-label verification has no criteria**: Where an icon is the persistent label for a field, WCAG offers no test for whether it is understood. Treat an icon-only label as a usability risk to be validated, not a compliance question to be argued.

4. **WCAG 2.2 vs. regulation lag**: Section 508 and EN 301 549 currently reference WCAG 2.0/2.1 AA in their incorporated text. Targeting WCAG 2.2 AA satisfies both today and absorbs the next refresh; do not downgrade a 2.2-only criterion (2.4.11, 2.4.13, 2.5.7, 2.5.8, 3.3.7, 3.3.8) on the grounds that the regulation has not caught up.

# Accessibility (WCAG 2.2 AA)

**Sources:** [WCAG 2.2](https://www.w3.org/TR/WCAG22/) · [WAI-ARIA Authoring Practices Guide](https://www.w3.org/WAI/ARIA/apg/) · [APG: Accessible Names and Descriptions](https://www.w3.org/WAI/ARIA/apg/practices/names-and-descriptions/) · [W3C WAI Images Tutorial](https://www.w3.org/WAI/tutorials/images/) · [W3C WAI Forms: Labels](https://www.w3.org/WAI/tutorials/forms/labels/) · [Material 3: Accessible design](https://m3.material.io/foundations/accessible-design/overview) · [Apple HIG: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) · [Section 508](https://www.section508.gov/) · [EN 301 549 v3.2.1](https://www.etsi.org/deliver/etsi_en/301500_301599/301549/03.02.01_60/en_301549v030201p.pdf) · [axe-core rule descriptions](https://github.com/dequelabs/axe-core/blob/develop/doc/rule-descriptions.md) · [W3C ACT Rules](https://www.w3.org/WAI/standards-guidelines/act/rules/) · [eslint-plugin-jsx-a11y](https://github.com/jsx-eslint/eslint-plugin-jsx-a11y)

## Summary
Targets WCAG 2.2 Level AA, the conformance level referenced by Section 508 (via the ICT Refresh) and by EN 301 549 for public-sector procurement in the EU. This file is the curated, checkable subset that reviews actually catch violations against: accessible names, state announcement, colour independence, form labelling, and image alternatives. Where a design system component already implements a pattern correctly, prefer it over a hand-rolled equivalent — every design system cited above ships components pre-wired for these criteria.

Rules below cite the [axe-core](https://github.com/dequelabs/axe-core) `ruleId` and, where one exists, the [W3C ACT Rules](https://www.w3.org/WAI/standards-guidelines/act/rules/) id alongside the WCAG success criterion, so a finding names a stable, publicly documented identifier rather than prose alone. See [Checkable Rule Vocabulary](#checkable-rule-vocabulary-axe-core-rule-ids--w3c-act-rules) for what those ids mean, which of them a source review can actually execute, and which it can only cite.

## Mandatory Rules

### DO
- Prefer the design system's own components over hand-rolled equivalents; they carry the roles, states, and focus handling already
- For a custom widget, implement a named pattern from the [ARIA Authoring Practices Guide](https://www.w3.org/WAI/ARIA/apg/) rather than inventing keyboard and role behaviour (axe `aria-roles`, `aria-required-attr`, `aria-required-children`, `aria-required-parent`; ACT `674b10`, `4e8ab6`, `bc4a75`, `ff89c9`)
- Give every interactive control a non-empty accessible name (SC 4.1.2 Name, Role, Value; axe `button-name`, `input-button-name`, `link-name`, `select-name`, `aria-command-name`, `aria-input-field-name`, `aria-toggle-field-name`; ACT `97a4e1`, `m6b1q3`, `c487ae`, `e086e5`)
- Make the accessible name of a control start with its visible label text, so speech-input users can address it (SC 2.5.3 Label in Name; axe `label-content-name-mismatch`; ACT `2ee8b8`)
- Announce state changes to assistive technology — `aria-expanded`, `aria-selected`, `aria-checked`, `aria-current` — and announce the control's new state before moving focus into the dialog or panel it opened (axe `aria-allowed-attr`, `aria-valid-attr`, `aria-valid-attr-value`, `aria-required-attr`; ACT `5c01ea`, `5f99a7`, `6a7281`, `4e8ab6` check that the attribute is permitted, spelled correctly, and carries a syntactically valid value — that the value is *true at the moment it is read* is not machine-checkable)
- Convey status with a text label or an icon in addition to colour (SC 1.4.1 Use of Color; axe covers only the link-in-body-text case, `link-in-text-block`)
- Give every input a visible, persistent label that stays on screen while the user types (SC 3.3.2 Labels or Instructions; axe `label`, `label-title-only`, `form-field-multiple-labels`; ACT `e086e5`)
- Associate the label programmatically: `<label for>`, wrapping `<label>`, or `aria-labelledby` pointing at visible text (axe `label`, `select-name`, `aria-input-field-name`; ACT `e086e5`)
- Provide `alt` text for informative images that conveys the same information the image conveys (SC 1.1.1 Non-text Content; axe `image-alt`, `input-image-alt`, `object-alt`, `svg-img-alt`, `role-img-alt`, `area-alt`; ACT `23a2a8`, `59796f`, `8fc3b6`, `7d6734`, `c487ae` — every one of them checks only that a name is *present*, never that it is *accurate*)
- Keep text as text; do not render informative copy as an image (SC 1.4.5 Images of Text)
- Maintain 4.5:1 contrast for body text and 3:1 for large text, UI component boundaries, and graphical objects that carry meaning (SC 1.4.3, SC 1.4.11; axe `color-contrast` / ACT `afw4f7` covers text against its background only — the 3:1 non-text requirement of SC 1.4.11 has no axe rule)
- Keep a visible focus indicator on every keyboard-focusable element, meeting the 3:1 contrast and minimum-area requirements (SC 2.4.7, SC 2.4.11 Focus Not Obscured, SC 2.4.13 Focus Appearance)
- Make every pointer-operable action reachable from the keyboard with no keyboard trap (SC 2.1.1, SC 2.1.2; axe `scrollable-region-focusable`, `frame-focusable-content`, `nested-interactive`, `aria-hidden-focus`; ACT `0ssw9k`, `akn7bn`, `307n5z`, `6cfa84`)
- Provide a pointer target of at least 24 by 24 CSS pixels, or adequate spacing around a smaller one (SC 2.5.8 Target Size (Minimum); axe `target-size` — no ACT rule)
- Offer a single-pointer alternative to any drag operation (SC 2.5.7 Dragging Movements)
- Announce asynchronous results — validation summaries, save confirmations, result counts — through a live region (SC 4.1.3 Status Messages)
- Keep the same component labelled the same way everywhere it appears (SC 3.2.4 Consistent Identification; axe `identical-links-same-purpose` / ACT `b20e66` covers the inverse link case — same name, different purpose)
- Support reflow to a 320 CSS pixel viewport width without two-dimensional scrolling (SC 1.4.10 Reflow; axe checks only the adjacent zoom-suppression failure — `meta-viewport` / ACT `b4f0c3`, against SC 1.4.4 Resize Text)
- Give the page a structure assistive technology can navigate: a document title, a declared language, one `main` landmark, headings in order, and list markup for lists (SC 1.3.1, SC 2.4.2, SC 3.1.1; axe `document-title`, `html-has-lang`, `landmark-one-main`, `region`, `heading-order`, `empty-heading`, `list`, `listitem`; ACT `2779a5`, `b5c3f8`, `ffd0e9`)

### DON'T
- Let the tooltip text and the `aria-label` of an icon-only control differ — a speech-input user says what they see (axe `label-content-name-mismatch`; ACT `2ee8b8`)
- Add `alt` text or an accessible name to an icon that sits beside text already naming the control; mark it `aria-hidden="true"` instead (axe `image-redundant-alt`)
- Ship a control whose accessible name is empty, is the icon file name, or is the word "button" (axe `button-name`, `input-button-name`, `link-name`; ACT `97a4e1`, `c487ae` — the empty case is deterministic; "is the icon file name" and "is the word button" are reviewer judgement)
- Use vague link text such as "Click here", "More", "Read more", or "Learn more" as the whole accessible name (SC 2.4.4 Link Purpose; axe `link-name` / ACT `c487ae` catches only an *empty* name — vagueness is reviewer judgement)
- Move focus into a dialog before the triggering control's state has been updated
- Rely on colour alone — red/green status dots, coloured chart series with no direct labels or patterns (SC 1.4.1; axe `link-in-text-block` covers links in body text and nothing else)
- Use placeholder text as the only label; it disappears on first keystroke and typically fails contrast (SC 3.3.2; axe `label`, `label-title-only`; ACT `e086e5`)
- Add `alt` text to a decorative image; use `alt=""` so screen readers skip it (axe `image-alt`, `presentation-role-conflict`; ACT `23a2a8`, `46ca7f`)
- Convey an instruction, a threshold, or a value only inside a screenshot or diagram
- Trigger navigation, submission, or a context change purely on focus or on value change without warning (SC 3.2.1, SC 3.2.2)
- Remove `:focus-visible` styling to "clean up" the design
- Suppress a real `<button>`/`<a>` in favour of a `<div>` with an `onClick` handler and no role, `tabindex`, or key handling (no axe rule — axe sees a rendered DOM, not a handler; the deterministic check is `eslint-plugin-jsx-a11y`'s `click-events-have-key-events`, `no-static-element-interactions`, and `interactive-supports-focus`)
- Force a tab order the DOM does not already have with a positive `tabindex` (axe `tabindex`; `eslint-plugin-jsx-a11y`'s `tabindex-no-positive`)

## Key Requirements by Category

### Accessible Controls

**Icon-only controls:**
- Mark the SVG `aria-hidden="true"` (and `focusable="false"` for legacy engines); do not give it `role="img"` when the parent control carries the name (axe `aria-hidden-focus`, `svg-img-alt`; ACT `6cfa84`, `7d6734`)
- Put the name on the control itself: `aria-label`, or a visually hidden text node (axe `button-name`, `link-name`; ACT `97a4e1`, `c487ae`)
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
- Every input needs its own associated label; a section heading is not a label (axe `label`; ACT `e086e5`)
- Required, format, and constraint information belongs in programmatically associated help text (`aria-describedby`), not only in the placeholder
- Error text is associated with the field via `aria-describedby` and the field is marked `aria-invalid="true"` (SC 3.3.1 Error Identification; axe `aria-valid-attr-value` / ACT `6a7281` checks that `aria-describedby` resolves to a real element — that the text it points at is the *right* text is reviewer judgement)

**Placeholder text:**
- Placeholder text is a hint, never a label — the label stays visible while the field has content
- If a placeholder is used, it must meet the 4.5:1 text contrast requirement like any other text
- Fields that commonly carry a format hint: date/time pickers, numeric inputs, password inputs, selects, code editors, filter fields, text areas, and text inputs — give each a real label plus a format hint where the expected input is not obvious

### Multimedia

**Images:**
- Classify every image as decorative or informative before writing markup
- Informative image → `alt` text conveying the same information; complex image (chart, diagram) → short `alt` plus a long description nearby or linked
- Decorative image → `alt=""` (or CSS background), never a missing `alt` attribute (axe `image-alt`, `presentation-role-conflict`; ACT `23a2a8`, `46ca7f`)
- Never use an image as the only carrier of an instruction, a value, or a threshold
- Render informative text as HTML so it can be zoomed, restyled, translated, and read aloud

## Checkable Rule Vocabulary (axe-core rule ids + W3C ACT Rules)

Every rule above that names an `axe` id is reportable as a stable, publicly documented identifier: [axe-core](https://github.com/dequelabs/axe-core)'s `ruleId`, and the [W3C ACT Rules](https://www.w3.org/WAI/standards-guidelines/act/rules/) id axe-core itself maps that rule to. ACT is a published W3C standard, not a vendor artefact, so the id survives a change of tool. **A bullet that cites no id has no deterministic equivalent** — it is reviewer judgement and the review must argue it in prose rather than assert a rule number.

Cite the id in the finding: `SC 1.1.1 · axe image-alt · ACT 23a2a8`. Never invent one — a rule id that does not exist is worse than prose, because it reads as verified.

### What can actually run, and what can only be cited

| Vocabulary / tool | Runs against | Executable during a source review? |
|---|---|---|
| axe-core `ruleId` (`image-alt`, `color-contrast`, …) | a **rendered DOM** | **No.** Cite the id; never claim the rule ran |
| W3C ACT rule id (`23a2a8`, `afw4f7`, …) | a rendered page — the rule text is a specification | **No.** It is a spec, not a runner |
| `eslint-plugin-jsx-a11y` rule (`alt-text`, `aria-props`, …) | JSX/TSX **source** | **Yes**, when the target repo configures it |
| `jest-axe`, `cypress-axe`, `@axe-core/playwright`, `@axe-core/cli` | a rendered app under test | **No.** A review has no rendered app |

axe-core needs a rendered DOM and cannot be pointed at source files. A review that reports an axe rule id is naming the rule a violation *would* trip, not reporting a rule that executed. Say which of the two happened; the distinction is the whole value of the identifier.

### axe rule id ↔ static equivalent

Where a repo configures `eslint-plugin-jsx-a11y`, these are the rules that cover the same ground on source. A finding the linter already reported is not re-raised by the review — see the merge rule in the `guideline-reviewer` agent.

| axe `ruleId` | ACT | WCAG / tag | `eslint-plugin-jsx-a11y` equivalent |
|---|---|---|---|
| `image-alt`, `input-image-alt`, `object-alt`, `svg-img-alt`, `role-img-alt` | `23a2a8`, `59796f`, `8fc3b6`, `7d6734` | 1.1.1 (wcag2a) | `alt-text` |
| `area-alt` | `c487ae` | 1.1.1, 2.4.4, 4.1.2 (wcag2a) | `alt-text` |
| `image-redundant-alt` | — | best-practice | `img-redundant-alt` |
| `link-name` | `c487ae` | 2.4.4, 4.1.2 (wcag2a) | `anchor-has-content`, `anchor-is-valid` |
| `identical-links-same-purpose` | `b20e66` | best-practice | `anchor-ambiguous-text` |
| `button-name`, `input-button-name` | `97a4e1`, `m6b1q3` | 4.1.2 (wcag2a) | `control-has-associated-label` (opt-in) |
| `label`, `select-name`, `aria-input-field-name`, `aria-toggle-field-name` | `e086e5` | 4.1.2 (wcag2a) | `label-has-associated-control` |
| `label-content-name-mismatch` | `2ee8b8` | 2.5.3 (wcag21a) | — |
| `aria-roles` | `674b10` | 4.1.2 (wcag2a) | `aria-role` |
| `aria-allowed-attr`, `aria-prohibited-attr` | `5c01ea` | 4.1.2 (wcag2a) | `role-supports-aria-props` |
| `aria-valid-attr` | `5f99a7` | 4.1.2 (wcag2a) | `aria-props` |
| `aria-valid-attr-value` | `6a7281` | 4.1.2 (wcag2a) | `aria-proptypes` |
| `aria-required-attr` | `4e8ab6` | 4.1.2 (wcag2a) | `role-has-required-aria-props` |
| `aria-required-children`, `aria-required-parent` | `bc4a75`, `ff89c9` | 1.3.1 (wcag2a) | — |
| `aria-hidden-focus` | `6cfa84` | 4.1.2 (wcag2a) | `no-aria-hidden-on-focusable` |
| `nested-interactive` | `307n5z` | 4.1.2 (wcag2a) | — |
| `scrollable-region-focusable` | `0ssw9k` | 2.1.1, 2.1.3 (wcag2a) | — |
| `frame-focusable-content` | `akn7bn` | 2.1.1 (wcag2a) | — |
| `frame-title` | `cae760` | 4.1.2 (wcag2a) | `iframe-has-title` |
| `tabindex` | — | best-practice | `tabindex-no-positive` |
| `autocomplete-valid` | `73f2c2` | 1.3.5 (wcag21aa) | `autocomplete-valid` |
| `document-title` | `2779a5` | 2.4.2 (wcag2a) | — |
| `html-has-lang`, `valid-lang` | `b5c3f8`, `de46e4` | 3.1.1 (wcag2a) | `html-has-lang`, `lang` |
| `empty-heading` | `ffd0e9` | best-practice | `heading-has-content` |
| `heading-order`, `page-has-heading-one`, `landmark-one-main`, `region` | — | best-practice | — |
| `list`, `listitem`, `definition-list`, `dlitem` | — | 1.3.1 (wcag2a) | — |
| `scope-attr-valid` | — | best-practice | `scope` |
| `th-has-data-cells`, `td-headers-attr` | `d0f69e`, `a25f45` | 1.3.1 (wcag2a) | — |
| `video-caption`, `audio-caption` | `eac66b`, `2eb176` | 1.2.2 (wcag2a) | `media-has-caption` |
| `marquee`, `blink` | — | 2.2.2 (wcag2a) | `no-distracting-elements` |
| `color-contrast`, `color-contrast-enhanced` | `afw4f7`, `09o5cg` | 1.4.3 (wcag2aa), 1.4.6 (wcag2aaa) | — (needs rendering) |
| `target-size` | — | 2.5.8 (wcag22aa) | — (needs layout) |
| `meta-viewport` | `b4f0c3` | 1.4.4 (wcag2aa) | — |
| `presentation-role-conflict` | `46ca7f` | best-practice | `no-redundant-roles` (adjacent) |
| — (no axe rule: a handler, not a rendered state) | — | 2.1.1 (wcag2a) | `click-events-have-key-events`, `no-static-element-interactions`, `interactive-supports-focus`, `mouse-events-have-key-events` |

Two tag caveats. A rule whose WCAG column reads `best-practice` is not a WCAG failure — report it as a recommendation, never as a conformance violation. And `label-content-name-mismatch` is tagged `experimental` in axe-core, so it is **off by default**: a repo's own axe run will not report it unless it opted in.

An ACT id marked in the W3C listing as *proposed* rather than *approved* (`2ee8b8`, `5c01ea`, `bc4a75`, `ff89c9`, `b20e66`, `d0f69e`, `cae760`, `ffd0e9`, `eac66b`, `2eb176`) is still a real, citable W3C rule — say "proposed" if the distinction matters to the audience, and never upgrade it silently.


---

## Open Questions / Ambiguities

1. **"Universally understood" icons are undefined**: The rule to add a tooltip unless the icon is a platform convention has no objective test. [NN/g's icon usability research](https://www.nngroup.com/articles/icon-usability/) finds that very few icons are universally recognised without a text label; treat the exemption as narrow and test with real users when it matters.

2. **State-announcement timing is implementation-specific**: "Announce state before moving focus" is achievable in most frameworks but the exact ordering depends on how the framework batches DOM updates. Verify with a screen reader rather than by code reading.

3. **Icon-as-label verification has no criteria**: Where an icon is the persistent label for a field, WCAG offers no test for whether it is understood. Treat an icon-only label as a usability risk to be validated, not a compliance question to be argued.

4. **WCAG 2.2 vs. regulation lag**: Section 508 and EN 301 549 currently reference WCAG 2.0/2.1 AA in their incorporated text. Targeting WCAG 2.2 AA satisfies both today and absorbs the next refresh; do not downgrade a 2.2-only criterion (2.4.11, 2.4.13, 2.5.7, 2.5.8, 3.3.7, 3.3.8) on the grounds that the regulation has not caught up.

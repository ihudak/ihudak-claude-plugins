# Filter Field

**Sources:** [APG: Combobox pattern](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/) · [Material 3: Search](https://m3.material.io/components/search/guidelines) · [Material 3: Text fields](https://m3.material.io/components/text-fields/guidelines) · [Apple HIG: Search fields](https://developer.apple.com/design/human-interface-guidelines/search-fields) · [Fluent 2](https://fluent2.microsoft.design/) · [NN/g: Filters vs. Facets](https://www.nngroup.com/articles/filters-vs-facets/) · [NN/g: Response Times — The 3 Important Limits](https://www.nngroup.com/articles/response-times-3-important-limits/) · [NN/g: Search Should Be Visible and Simple](https://www.nngroup.com/articles/search-visible-and-simple/) · [WCAG 2.2 SC 3.2.2 On Input](https://www.w3.org/WAI/WCAG22/Understanding/on-input.html) · [SC 3.3.2 Labels or Instructions](https://www.w3.org/WAI/WCAG22/Understanding/labels-or-instructions.html) · [SC 4.1.3 Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html)

## Summary
Harmonises the **filter field** — the advanced, expression-based filtering control — so filtering behaves the same way across an application. Use a filter field when the user needs to express a query over a large or complex dataset: boolean composition, comparison operators, or partial matching. Use a simpler control (a **filter bar** of faceted selects, or a plain search input) when the user only needs to pick values from a bounded set. Both patterns are combobox-shaped for assistive technology and follow the [APG combobox pattern](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/).

## Mandatory Rules

### DO
- Keep the implementation aligned with the documented syntax of the filter field's own grammar; document that grammar publicly and link to it from the field
- Use a filter field when the dataset is large or has many attributes and the user composes rather than selects
- Use a filter field when the user needs boolean composition, comparison operators (`=`, `!=`, `<`, `>`, `<=`, `>=`), or partial matching (starts-with, contains, ends-with)
- Place the filter field **above** the content it scopes, in reading order and in the DOM
- Place it as close as possible to that content, with no unrelated interactive content in between
- Give the field a persistent visible label and a leading filter affordance (SC 3.3.2 — see `accessibility.md`)
- Debounce the suggestion request: wait at least 300 ms after the last keystroke before fetching
- Cache suggestions already fetched for the same prefix, and serve from cache while the network request is in flight
- Bound the suggestion payload the backend returns, and page or truncate rather than streaming an unbounded list
- Cancel superseded in-flight requests (`AbortController` or the platform equivalent), so a slow early response never overwrites a fast later one
- Keep the input responsive at all times — typing, caret movement, and selection must never wait on the network ([NN/g: 0.1 s / 1 s / 10 s limits](https://www.nngroup.com/articles/response-times-3-important-limits/))
- Render validation messages in a form-field message region associated with the input via `aria-describedby`, and mark the field `aria-invalid` when the expression does not parse
- Declare the valid keys, the operators each key's data type accepts, and the value shape in one validation map, so the same definition drives suggestions, validation, and error text
- Surface backend-originated failures distinctly from syntax errors — a timeout, a permission denial, and a malformed expression are three different messages
- Insert exactly what the suggestion label displays, apart from escaping required by the grammar
- Match suggestions case-insensitively
- Order key and value suggestions most-relevant first
- Rank matches: exact match, then starts-with match, then other partial matches
- Show a data-type indicator (icon or type label) on key suggestions
- Offer operator suggestions once the user has selected a key or typed a space after one
- Offer value suggestions once the user has selected an operator or typed a space after one
- Offer the `OR` suggestion once a filter statement is complete, below the key suggestions
- Match values case-insensitively; treat keys as case-sensitive
- Confirm before clearing a non-empty filter expression
- Provide an explicit Apply control adjacent to the field
- Style Apply as low-emphasis when the expression is empty or already applied, and as the primary action when the expression has changed and is unapplied
- Show a progress indicator inside the Apply control while the query runs, and turn it into a cancel control for the duration
- Keep Apply focusable and operable at all times; communicate "nothing to apply" through its style, never by disabling it
- Support `Cmd+Enter` (macOS) / `Ctrl+Enter` (Windows, Linux) to apply from anywhere in the field
- Submit on `Enter` while the input has focus and no suggestion is highlighted
- Announce the result count after a filter is applied via a live region (SC 4.1.3)

### DON'T
- Alter the documented grammar, operator set, or precedence rules per-app
- Use a filter field for a simple bounded-choice scenario — use a filter bar of facets ([NN/g: Filters vs. Facets](https://www.nngroup.com/articles/filters-vs-facets/))
- Render both a filter field and a filter bar scoping the same dataset — the user cannot tell which one is in effect
- Fire a request on every keystroke with no debounce
- Run expensive synchronous work inside the suggestion callback — it blocks input
- Insert an `AND` operator the user did not type; conjunction is implicit
- Insert an `OR` operator automatically; disjunction is always explicit
- Auto-join several values of one key with `OR`; offer the set/membership form (`in (…)`) instead
- Override the field's own built-in suggestion sources (recently used, pinned, in-field search)
- Include grammar escape characters in a suggestion label unless they are part of the literal key or value
- Let an earlier or later clause in the expression narrow the suggestions offered for the clause being edited
- Offer an operator the key's data type does not support
- Auto-insert an operator immediately after a key is chosen
- Reorder the default operator suggestions unless the first one would not produce a useful result for that key
- Suggest `AND` — it is implicit and handled by the grammar
- Group suggestions under generic headings such as "Key suggestions"
- Apply the filter while the user is still typing; applying is always an explicit act (SC 3.2.2 On Input)
- Disable the Apply control as a way of signalling that there is nothing to apply

## Scenarios

### Value suggestion exceptions
Do not offer value suggestions when:
- The operator is starts-with, ends-with, contains, exists, or a phrase match — the point of those operators is that the value is not enumerable
- The value is a duration or a number, where the space of values is unbounded
Offer them in those cases only where a bounded, genuinely useful candidate set exists (for example, a numeric field with fewer than a dozen distinct values in practice).

### Filter statement suggestions (optional)
Where whole-statement suggestions are implemented:
- Render them below the key suggestions
- Suggest complete statements: key, operator, and the value the user has typed
- Rank statements matching the typed value above statements built from merely popular keys

### Choosing between filter controls
- Bounded choice from a known set, one or two attributes → filter bar (faceted selects or chips)
- Free-text lookup over one field → search input ([Material 3: Search](https://m3.material.io/components/search/guidelines))
- Composition over many attributes with operators → filter field
- Never two of these over the same dataset at once

---

## Open Questions / Ambiguities

1. **"Relevance" is domain-specific**: Ordering suggestions by relevance has no universal definition. Products should define a concrete ranking signal per dataset (recency of use, cardinality, schema order) and state it, so the ordering is reviewable rather than a matter of taste.

2. **"Truly helpful" is subjective**: The value-suggestion exceptions leave a judgement call. Make it once per field, in code, against a stated cardinality threshold — not per review.

3. **Payload size has no fixed limit**: "Bound the payload" is unquantified. A defensible default is to cap the suggestion list at what fits two screens (roughly 50 entries) and to page beyond that; measure against the 1-second interaction budget from [NN/g's response-time limits](https://www.nngroup.com/articles/response-times-3-important-limits/) rather than a byte count.

4. **Debounce floor vs. perceived latency**: 300 ms is a floor for request volume, not a target for perceived responsiveness. The field's own rendering — caret, token highlighting, syntax colouring — must stay under 100 ms regardless of the debounce.

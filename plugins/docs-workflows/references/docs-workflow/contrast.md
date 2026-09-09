# Contrast — the accessibility rule this family carries itself

**Why this file exists.** `/docs-brand` derives a palette from a product's own code and must not apply one that makes body text unreadable. The rule it needs is a threshold pair and a formula, not a review rulebook — so the family carries it rather than reaching into `guideline-reviewers`, whose `references/guidelines/accessibility.md` states the same rule inside 183 lines of application-UI review vocabulary and is not loadable from `docs-workflows` at all (design D24). That file is worth reading and is cited here as further reading; **nothing loads it at runtime**, so an install without that plugin behaves identically.

## 1. The thresholds

| What | Minimum contrast ratio | WCAG 2.2 success criterion |
|---|---|---|
| Body text against its background | **4.5:1** | SC 1.4.3 Contrast (Minimum) |
| Large text — 18pt / 24px, or 14pt / 18.66px bold — against its background | **3:1** | SC 1.4.3 |
| UI component boundaries, and graphical objects that carry meaning | **3:1** | SC 1.4.11 Non-text Contrast |
| A visible focus indicator | **3:1** | SC 2.4.7, SC 2.4.11, SC 2.4.13 |

`/docs-brand` checks the first three. The fourth is named because a theme that overrides focus styling can fail it, and the command reports rather than fixes.

## 2. The formula

Contrast ratio is `(L1 + 0.05) / (L2 + 0.05)`, where `L1` is the relative luminance of the lighter colour and `L2` of the darker.

Relative luminance of an sRGB colour, per WCAG 2.2:

```
for each channel C in {R, G, B}, with c = C / 255:
    c_lin = c / 12.92                      if c <= 0.04045
    c_lin = ((c + 0.055) / 1.055) ** 2.4   otherwise

L = 0.2126 * R_lin + 0.7152 * G_lin + 0.0722 * B_lin
```

Worked example — `#1565C0` on `#FFFFFF`:

```
R = 0x15 = 21   -> 21/255  = 0.0824 -> ((0.0824+0.055)/1.055)^2.4 = 0.00605
G = 0x65 = 101  -> 101/255 = 0.3961 -> 0.13287
B = 0xC0 = 192  -> 192/255 = 0.7529 -> 0.52712
L1(white) = 1.0
L2        = 0.2126*0.00605 + 0.7152*0.13287 + 0.0722*0.52712 = 0.13444
ratio     = (1.0 + 0.05) / (0.13444 + 0.05) = 5.69:1     -> passes SC 1.4.3
```

Report the ratio to two decimal places. Never report a pass or fail without the number.

## 3. Adjudication

- A derived colour that **fails** is reported as a finding naming the measured ratio, the pair it was measured against, and the criterion — never silently accepted and never silently corrected.
- **It is still applied if the operator confirms.** It is their brand; the command's job is that the choice is informed, not that it is overridden. The finding is carried into the PR message so the decision is visible to a reviewer.
- A **passing** colour produces no output. Silence is the pass signal.

## Further reading

`guideline-reviewers`' `references/guidelines/accessibility.md` covers WCAG 2.2 AA across an application's whole UI — keyboard navigation, accessible names, form fields, media — with the axe-core and W3C ACT rule ids for each. It is the right document for reviewing a product; it is not loadable from this plugin and nothing here reads it.

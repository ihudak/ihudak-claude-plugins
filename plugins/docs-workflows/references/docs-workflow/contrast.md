# Contrast — the accessibility rule this family carries itself

Single source of truth for the accessibility rule a derived brand palette is held to: the threshold pair, the formula, and what happens to a colour that fails.

Consumed by `/docs-brand`, both standalone and as `/docs-init`'s branding phase. Its entry points, so a command can say which part it is executing: **the thresholds** (§1), **the formula** (§2), and **the adjudication** (§3).

---

**Why this file exists.** `/docs-brand` derives a palette from a product's own code and must not apply one that makes body text unreadable. The rule it needs is a threshold pair and a formula, not a review rulebook — so the family carries it rather than reaching into `guideline-reviewers`, whose `references/guidelines/accessibility.md` states the same rule inside 183 lines of application-UI review vocabulary and is not loadable from `docs-workflows` at all (design D24). That file is worth reading and is cited here as further reading; **nothing loads it at runtime**, so an install without that plugin behaves identically.

## 1. The thresholds

| What | Minimum contrast ratio | WCAG 2.2 success criterion |
|---|---|---|
| Body text against its background | **4.5:1** | SC 1.4.3 Contrast (Minimum) |
| Large text — 18pt / 24px, or 14pt / 18.66px bold — against its background | **3:1** | SC 1.4.3 |
| UI component boundaries, and graphical objects that carry meaning | **3:1** | SC 1.4.11 Non-text Contrast |
| A visible focus indicator | **3:1** | SC 2.4.7, SC 2.4.11, SC 2.4.13 |

`/docs-brand` checks every derived colour — the confirmed primary, its derived light and dark variants, and the confirmed accent — against the **first row alone** (body text, 4.5:1). It derives a colour pair and cannot know which UI components a theme will draw with it, so rather than guess whether a given colour ends up governing body text, large text, or a component boundary, it applies the strictest of the rows a text-role colour could plausibly be held to: a pass on the first row implies a pass on the second and third for the same pair, since all three are the same computed ratio measured against three different bars. The second and third rows are named here as the thresholds a docs-scaffold theme *is* held to even though `/docs-brand` never computes them separately. The fourth (focus indicator) is named for a different reason: a theme that overrides focus styling can fail it, but `/docs-brand` neither derives nor touches focus styling, so it is entirely outside this command's reach — named here so a future focus-styling check has a threshold to cite rather than a fourth reason to invent one.

## 2. The formula

Contrast ratio is `(L1 + 0.05) / (L2 + 0.05)`, where `L1` is the relative luminance of the lighter colour and `L2` of the darker.

Relative luminance of an sRGB colour, per WCAG 2.2:

```
for each channel C in {R, G, B}, with c = C / 255:
    c_lin = c / 12.92                      if c <= 0.04045
    c_lin = ((c + 0.055) / 1.055) ** 2.4   otherwise

L = 0.2126 * R_lin + 0.7152 * G_lin + 0.0722 * B_lin
```

Worked example — `#1565C0` on `#FFFFFF`. Every intermediate is shown so the next reader can **check** this rather than trust it:

```
channel   8-bit      c = C/255    (c+0.055)/1.055    ^2.4 = c_lin
R = 0x15    21        0.082353        0.130192          0.00750
G = 0x65   101        0.396078        0.427562          0.13014
B = 0xC0   192        0.752941        0.765821          0.52712

L2 = 0.2126*0.00750 + 0.7152*0.13014 + 0.0722*0.52712
   =    0.00159     +    0.09308     +    0.03806        = 0.13273
L1 = 1.0                                                  (white)

ratio = (1.0 + 0.05) / (0.13273 + 0.05)
      = 1.05 / 0.18273
      = 5.75:1                                            -> passes SC 1.4.3
```

Report the ratio to two decimal places. Never report a pass or fail without the number.

**The number is the interface, so it is worth stating why this example is spelled out to five places.** An earlier revision of this file carried a worked example whose R and G channels and final ratio were wrong (0.00605, 0.13287, 5.69:1) while its verdict — passes — was right. A wrong example with a right verdict is the dangerous kind: nothing about the outcome looks off, so someone checking a correct implementation against it concludes their own code is broken and "fixes" it to reproduce the wrong figure. Recompute the three `c_lin` values before trusting any example, this one included.

## 3. Adjudication

- A derived colour that **fails** is reported as a finding naming the measured ratio, the pair it was measured against, and the criterion — never silently accepted and never silently corrected.
- **It is still applied if the operator confirms.** It is their brand; the command's job is that the choice is informed, not that it is overridden. The finding is carried into the PR message so the decision is visible to a reviewer.
- A **passing** colour produces no output. Silence is the pass signal.

## Further reading

`guideline-reviewers`' `references/guidelines/accessibility.md` covers WCAG 2.2 AA across an application's whole UI — keyboard navigation, accessible names, form fields, media — with the axe-core and W3C ACT rule ids for each. It is the right document for reviewing a product; it is not loadable from this plugin and nothing here reads it.

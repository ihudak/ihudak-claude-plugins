# Alerting Terminology

**Sources:** [Apple HIG: Alerts](https://developer.apple.com/design/human-interface-guidelines/alerts) · [Apple HIG: Notifications](https://developer.apple.com/design/human-interface-guidelines/notifications) · [Apple HIG: Writing](https://developer.apple.com/design/human-interface-guidelines/writing) · [Material 3: Word choice](https://m3.material.io/foundations/content-design/style-guide/word-choice) · [Material 3: Snackbar](https://m3.material.io/components/snackbar/guidelines) · [Microsoft Writing Style Guide](https://learn.microsoft.com/en-us/style-guide/welcome/) · [Google developer documentation style: word list](https://developers.google.com/style/word-list) · [NN/g: Error Message Guidelines](https://www.nngroup.com/articles/error-message-guidelines/)

## Summary
Defines consistent terminology for alerts and notifications across an application or product suite, so a user who learns the vocabulary in one surface finds the same functionality under the same word everywhere else. The distinction that matters is **required response**, not delivery channel or severity. Both Apple's HIG and Material's content guidance draw the same line: an alert interrupts because action is needed; a notification informs and can be deferred.

## Mandatory Rules

### DO
- Pick the term from the required user response, not from the delivery mechanism or the visual treatment
- Use **alert** when a signal condition requires timely action by a person or an automation
- Use **notification** when a message informs the recipient and no timely action is implied
- Define both terms once in the product glossary and link every UI surface, API field, and doc page to that definition
- Keep one canonical name per capability across every app, API, setting name, and doc page in the suite
- Use sentence case and the product's content style guide for every user-facing string, per [Microsoft](https://learn.microsoft.com/en-us/style-guide/welcome/) or [Google](https://developers.google.com/style/word-list) style guidance
- Update every dependent surface in the same change when renaming a capability — UI strings, settings labels, API field names, docs, and release notes
- Record a deprecation path when a public name changes: keep the old name resolving, and state the removal date

### DON'T
- Use "alert" and "notification" interchangeably in the same product
- Give the same capability different names in different apps ("alert rule" in one, "notification policy" in another)
- Reuse one name for two different things ("notification" meaning both a delivery channel and an alert payload)
- Derive the term from urgency colour or icon — a red banner that needs no response is still a notification
- Rename a user-facing term without also updating docs, API field names, and the glossary
- Introduce a synonym ("warning", "signal", "event", "incident") for an existing concept without adding it to the glossary and stating how it differs

## Definitions

**Alert**
A condition detected within a defined scope that requires timely action from a notified person or an automated responder. The defining property is the required response: if nobody has to do anything, it is not an alert.

**Notification**
A message delivered to a user through a channel — in-product inbox, email, mobile push, chat integration — that informs without requiring a timely response. A notification may *carry* an alert; the two are not the same object. Apple's HIG treats notifications as interruptions to be earned and Material treats a snackbar as informational-with-no-required-action, which is the same boundary stated from two directions.

**Channel**
The transport a notification travels over. A channel is never the name of the concept it carries: "email" is a channel, not a kind of alert.

---

## Open Questions / Ambiguities

1. **"Timely" is unquantified**: The alert/notification split hinges on whether action is needed *in time*, but no public style guide fixes a threshold. Products should state their own boundary (for example, "within the current on-call shift") in the glossary rather than leaving it to each team.

2. **Edge cases at the boundary**: A message that needs action from *someone*, but not urgently — a certificate expiring in 60 days, a quota at 80 percent — sits between the definitions. Pick one term per class of message and record the decision; do not leave it to the implementer.

3. **Ownership of the rename process**: The rule to update related documentation does not say who owns it. Assign the rename to a single owner with a checklist covering UI strings, API fields, settings labels, docs, and release notes, or renames will land partially.

4. **Localisation**: Some languages do not preserve the alert/notification distinction with two distinct everyday words. Flag the pair for translators explicitly; see [Microsoft's globalization guidance](https://learn.microsoft.com/en-us/globalization/).

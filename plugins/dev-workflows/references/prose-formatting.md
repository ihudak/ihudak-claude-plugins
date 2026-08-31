# Prose formatting — no hard-wrap (embedded — shared reference)

Every authored artifact (PRD, Epic, ARD, spec, design, product doc, release note, idea) is reviewed
in Obsidian or IntelliJ Idea — both soft-wrap markdown to the pane width — and is routinely
copy-pasted into trackers, review tools and chat. Hard-wrapping prose at a fixed column width (the common ~80–100 char
convention for raw-terminal readability) is redundant in both viewers and actively harmful in
on paste: every wrap point becomes a spurious line/paragraph break that the user must manually clean
up, and it confuses tools like Grammarly that rely on sentence boundaries.

## Rule

Never hard-wrap prose. Write each paragraph, list-item body, or other prose block as **one
unbroken line** in the source file, however long. Let the viewer wrap it for reading.

This applies to free-form prose (Problem, Goal, narrative descriptions, Summary bodies, Business
value, etc.). It does not apply to:
- Markdown structure that requires line breaks (headings, list markers, table rows, code blocks).
- A genuinely short line (a heading, a one-clause bullet) — the rule is about not *introducing*
  artificial breaks inside a paragraph, not about padding short content out.

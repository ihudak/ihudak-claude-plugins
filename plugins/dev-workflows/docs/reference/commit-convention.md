# Commit convention

**End your commit subject with the work's key, in square brackets.**

```
feat(orders): add order intake [ACME-77-01]
fix(billing): correct proration on mid-cycle upgrade [ACME-77-02]
```

That is the whole rule. Everything below is why it exists and what it buys you.

## Why it matters

[`/document`](../commands/document.md) and [`/release-notes`](../commands/release-notes.md) ground
their prose in the diff that actually shipped. They find that diff two ways: from
`implementation.md`, which [`/implement`](../commands/implement.md) writes for the work it did, and
from a scan of your repository's commit messages for the key.

The scan is what finds **everything the plugin did not do itself** — the commit you wrote by hand
after the session ran out, the fix a colleague pushed, the follow-up nobody ran a command for. A
commit whose subject names the key is one those commands can find. A commit that names nothing is
invisible to them, and the release note or the documentation page comes out thinner than the work
was.

## Where the key comes from

It is the `key:` in the frontmatter of the folder you are working in — the same key the folder is
named for. `/implement` also puts it in the branch name it creates (`<prefix>/<key>-<slug>`), so if
you are on that branch it is already in front of you.

## If you also use a tracker

Add its identifier as a trailer:

```
feat(orders): add order intake [ACME-77-01]

Work-Item: CU-8x9f2a1
```

The plugin never mints, validates, or looks that identifier up — it records it as `workitem_key` in
the folder's frontmatter if you put it there, preserves it across every rewrite, and includes it in
the commit scan. Your own tracker integration can do whatever it likes with the trailer.

## Why the subject and not a trailer

A trailer does not survive `git log --oneline`. The person deciding what their commit should look
like is scrolling the log, and they copy what they see — so a convention that lives only in the
trailer is a convention nobody sees.

## Who writes it

| | |
|---|---|
| [`/vuln`](../commands/vuln.md) | commits and opens a PR itself, so it writes a compliant subject |
| [`/implement`](../commands/implement.md), [`/upgrade`](../commands/upgrade.md) | leave their changes **uncommitted** on the branch — **you** write that commit, so they state this convention when they hand over |

Most commits in a repository this plugin has touched are written by a person, not by the plugin.
That is exactly why the convention is documented here rather than left implicit in what the plugin
emits.

## See also

- [`implementation-format.md`](../../references/implementation-format.md) — the record `/implement`
  writes, the scan that supplements it, and the different boundary each consumer takes.
- [`/implement`](../commands/implement.md) — where the branch and the handover happen.

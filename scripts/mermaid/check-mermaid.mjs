#!/usr/bin/env node
// check-mermaid.mjs -- every ```mermaid block in every tracked markdown file must parse.
//
// WHY THIS GATE EXISTS. GitHub draws a ```mermaid fence as a diagram, and where the
// diagram does not parse it shows "Unable to render rich display" and a parse error in
// its place. Before this gate nothing in the repository parsed mermaid (check-docs.sh's
// check 15 extracts diagrams, but only to test which commands appear in one), so a broken
// diagram passed every gate: plugins/product-workflows/docs/workflow.md shipped from
// product-workflows 3.0.0 onward with five unquoted edge labels carrying `[BR#n]`,
// `[CG#n]/[DG#n]` and `[AC#n]/[FR#n]` -- mermaid reads a `[` inside an edge label as the
// start of a node shape -- and it was found by a person opening the page on GitHub.
//
// FINDING THE DIAGRAMS. Blocks are found with a real CommonMark lexer (marked, pinned in
// package.json), never with a hand-rolled fence scanner. The first version of this gate
// used one, and a release review found three kinds of diagram GitHub draws that it never
// saw -- a fence inside a blockquote, a fence on a list-marker line, and any diagram after
// a line opening with an inline code span of three or more backticks, which the scanner
// took for a fence because it did not know a backtick fence's info string may not contain
// a backtick -- plus a false rejection of a four-space-indented block, which CommonMark
// makes an indented code block that GitHub shows as text. A lexer gets all four right by
// construction. Its count agreed with GitHub's own renderer on this tree.
//
// WHAT IT CHECKS, AND WHAT IT DOES NOT. It runs mermaid's own parser over every block.
// Parsing is the failure GitHub reports, and the gate was calibrated against that report:
// on the broken page it reproduces GitHub's exact error (the same line, the same caret,
// "got 'SQS'"), and across this tree it agreed block for block with a real headless render
// (mermaid-cli, a browser). It does NOT render, so a diagram that parses and then fails at
// layout passes; that class did not occur here, and a render needs a browser CI does not
// carry. A mermaid fence inside a raw HTML block is outside it too, as it is outside any
// CommonMark lexer.
//
// WHERE IT POINTS. A failure names the SOURCE-FILE line, found by content rather than by
// arithmetic. mermaid numbers its errors from text it has already rewritten -- it
// preprocesses twice, removes frontmatter, directives, %% comments and leading whitespace,
// and a diagram's own parser rewrites more (flowchart collapses a `}` followed by blank
// lines) -- so its line number cannot be mapped back by replaying what it did: a replay is
// never complete, and an incomplete one points confidently at the wrong line. What every
// parse and lexical error does carry is the text around the failure with a caret under it.
// locateError finds that text in the diagram, ignoring whitespace and the lines mermaid
// never parses, and trusts it only where it occurs exactly once; otherwise it names the
// fence line and says so. It never guesses.
//
// WHAT IS NOT A DEFECT. A fence that is never closed runs to the end of its container --
// the end of the file at the top level, the end of the item inside a list -- and GitHub
// draws what it holds. So an unclosed fence is not rejected for being unclosed; only its
// content is judged. Where an unclosed top-level fence fails to parse, the report says the
// diagram ran to the end of the file, since that is almost always why.
//
// THE VERSION PIN. GitHub does not publish the mermaid version it serves. The failure
// above reproduced identically on mermaid 10.9.8, 11.17.2 and 12.0.0, so the pin is the
// mature 11.x line. package.json pins exact versions and package-lock.json is committed,
// so neither the parser nor the lexer can change under the gate between two runs; moving
// either is an edit to package.json plus a regenerated lockfile, taken deliberately -- and
// the selftest's line cases are what will say if a new mermaid changes the context it prints.
//
// SCOPE. Tracked markdown only (`git ls-files`), because a tracked file is what GitHub
// renders -- which also leaves out every git worktree copy under the ignored .worktrees/.
// The one subtree excluded is this gate's own fixture tree, scripts/fixtures/mermaid/ --
// its green cases as well as its red ones, which are broken on purpose.
//
// Usage: node scripts/mermaid/check-mermaid.mjs [--root <dir>]   (default --root .)
//        node scripts/mermaid/check-mermaid.mjs --selftest
// Exit:  0 every block parses; 1 a block does not, or no block was found; 2 usage error.

import { JSDOM } from 'jsdom';
import { marked } from 'marked';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const FIXTURES = path.resolve(HERE, '../fixtures/mermaid');
const EXCLUDED_PREFIX = 'scripts/fixtures/mermaid/';

// mermaid.parse() sanitises labels through DOMPurify, which needs a window. jsdom supplies
// one; nothing is rendered, so no layout engine is needed.
const dom = new JSDOM('<!doctype html><html><body></body></html>');
globalThis.window = dom.window;
globalThis.document = dom.window.document;
Object.defineProperty(globalThis, 'navigator', { value: dom.window.navigator, configurable: true });
const mermaid = (await import('mermaid')).default;
mermaid.initialize({ startOnLoad: false });
const version = (pkg) => JSON.parse(
  fs.readFileSync(path.join(HERE, 'node_modules', pkg, 'package.json'), 'utf8')).version;
const MERMAID_VERSION = version('mermaid');

const newlines = (s) => (s.match(/\n/g) || []).length;

// Every mermaid code block, with the source line of its opening fence. Line tracking: the
// raws of a token list concatenate back to its source, and a container (blockquote, list
// item) strips a prefix from each of its lines without adding or removing one -- so a token
// nested inside starts on its container's first line plus the newlines in the raws before
// it. GitHub takes a block's language from the first word of its info string.
function extractBlocks(text) {
  const blocks = [];
  const walk = (tokens, firstLine, depth) => {
    let line = firstLine;
    for (const t of tokens) {
      if (t.type === 'code' && t.codeBlockStyle !== 'indented'
          && (t.lang ?? '').trim().split(/\s+/)[0] === 'mermaid') {
        // Inside a container, the container's end closes the fence: that is not a defect.
        blocks.push({ fenceLine: line, src: t.text, runsToEof: depth === 0 && !closesItsFence(t.raw) });
      } else if (t.type === 'blockquote') {
        walk(t.tokens, line, depth + 1);
      } else if (t.type === 'list') {
        let itemLine = line;
        for (const item of t.items) { walk(item.tokens, itemLine, depth + 1); itemLine += newlines(item.raw); }
      }
      line += newlines(t.raw);
    }
  };
  // marked normalises CRLF and CR to LF itself; the selftest's CRLF case pins that.
  walk(marked.lexer(text), 1, 0);
  return blocks;
}

// Whether a fenced block ends on a closing fence of its own. Used only to explain a failure:
// CommonMark runs an unclosed top-level fence to the end of the file.
function closesItsFence(raw) {
  const lines = raw.replace(/\n+$/, '').split('\n');
  const open = lines[0].trim().match(/^(`{3,}|~{3,})/);
  if (!open || lines.length < 2) return false;
  const close = new RegExp(`^${open[1][0] === '`' ? '`' : '~'}{${open[1].length},}\\s*$`);
  return close.test(lines[lines.length - 1].trim());
}

// The lines mermaid never parses, hidden before a search so a failure's context can be
// found across them. These are mermaid 11.17.2's own frontmatter and directive regexes;
// they only ever REMOVE text from the search, so an imperfect one can cost a match (and
// fall back to the fence line), never produce a wrong line.
const FRONTMATTER = /^([^\S\n\r]*)-{3}\s*[\n\r](.*?)[\n\r]\1-{3}\s*[\n\r]+/s;
const DIRECTIVE = /%{2}{\s*(?:(\w+)\s*:|(\w+))\s*(?:(\w+)|((?:(?!}%{2}).|\r?\n)*))?\s*(?:}%{2})?/gi;
const COMMENT_LINE = /^[ \t]*%%(?!{)[^\n]*$/gm;

// Find where mermaid's error is, from the context it prints -- up to twenty characters
// before the failure, a caret, and what follows, all with newlines removed. Returns
// { line } (0-based, within the diagram) or { reason } where it declines: mermaid printed
// no context, the context is not in the diagram, or it is there more than once. A caller
// then names the fence line and the reason, instead of guessing.
function locateError(blockText, message) {
  const m = message.match(/^(?:Parse|Lexical) error on line \d+[^\n]*\n([^\n]*)\n(-*)\^/);
  if (!m) return { reason: 'mermaid printed no location' };
  let pre = m[1].slice(0, m[2].length);
  let post = m[1].slice(m[2].length);
  if (pre.startsWith('...')) pre = pre.slice(3);
  if (post.endsWith('...')) post = post.slice(0, -3);
  const norm = (x) => x.replace(/\s+/g, '').replace(/'/g, '"');
  const needle = norm(pre + post);
  const at = norm(pre).length;
  if (needle.length < 6) return { reason: 'the failure\'s context is too short to pin' };
  const text = blockText.replace(/\r\n?/g, '\n');
  const hidden = new Uint8Array(text.length);
  const fm = text.match(FRONTMATTER);
  if (fm) hidden.fill(1, 0, fm[0].length);
  for (const re of [DIRECTIVE, COMMENT_LINE]) {
    for (const x of text.matchAll(re)) hidden.fill(1, x.index, x.index + x[0].length);
  }
  let view = '';
  const offsets = [];
  for (let i = 0; i < text.length; i++) {
    if (hidden[i] || /\s/.test(text[i])) continue;
    view += text[i] === "'" ? '"' : text[i];
    offsets.push(i);
  }
  const first = view.indexOf(needle);
  if (first < 0) return { reason: 'the failure\'s context is not in the diagram' };
  if (view.indexOf(needle, first + 1) >= 0) return { reason: 'the failure\'s context occurs more than once' };
  return { line: newlines(text.slice(0, offsets[first + Math.min(at, needle.length - 1)])) };
}

// Check one set of files. Returns { blocks, failures }, each failure "file:line: message".
async function checkFiles(files, displayRoot) {
  let blocks = 0;
  const failures = [];
  for (const file of files) {
    const rel = path.relative(displayRoot, file);
    for (const b of extractBlocks(fs.readFileSync(file, 'utf8'))) {
      blocks++;
      try {
        await mermaid.parse(b.src);
      } catch (e) {
        const msg = String(e?.message ?? e);
        const detail = msg.split('\n').filter(Boolean).slice(0, 3).join(' | ');
        const at = locateError(b.src, msg);
        const eof = b.runsToEof ? ' -- this fence is never closed, so the diagram runs to the end of the file' : '';
        failures.push(at.line === undefined
          ? `${rel}:${b.fenceLine}: (in the diagram opening here; ${at.reason}) ${detail}${eof}`
          : `${rel}:${b.fenceLine + 1 + at.line}: ${detail}${eof}`);
      }
    }
  }
  return { blocks, failures };
}

// The verdict, shared by the real run and --selftest so the selftest exercises the gate's
// own guard rather than a copy of it.
function verdict({ blocks, failures }) {
  // Vacuity guard, the shape check-docs.sh's checks 11 and 17 use: a tree that carries
  // diagrams and reports none has an extractor that stopped matching, not nothing to check.
  if (blocks === 0) return { exit: 1, reason: 'vacuous' };
  return { exit: failures.length ? 1 : 0, reason: failures.length ? 'failures' : 'pass' };
}

function walkMarkdown(dir) {
  const out = [];
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) out.push(...walkMarkdown(p));
    else if (e.name.endsWith('.md')) out.push(p);
  }
  return out.sort();
}

function trackedMarkdown(root) {
  try {
    execFileSync('git', ['-C', root, 'rev-parse', '--is-inside-work-tree'], { stdio: 'ignore' });
  } catch {
    console.error(`check-mermaid: ${root} is not a git work tree -- the gate checks tracked files, which is what GitHub renders`);
    process.exit(2);
  }
  const top = execFileSync('git', ['-C', root, 'rev-parse', '--show-toplevel'], { encoding: 'utf8' }).trim();
  const listed = execFileSync('git', ['-C', top, 'ls-files', '-z', '--', '*.md'], { encoding: 'utf8' });
  const files = listed.split('\0').filter(Boolean)
    .filter((f) => !f.startsWith(EXCLUDED_PREFIX))
    .map((f) => path.join(top, f));
  return { top, files };
}

async function runRoot(root) {
  const { top, files } = trackedMarkdown(root);
  const { blocks, failures } = await checkFiles(files, top);
  const v = verdict({ blocks, failures });
  if (v.reason === 'vacuous') {
    console.error('FAIL: found no ```mermaid blocks in any tracked markdown file -- the extractor has stopped matching; this tree carries diagrams');
    return 1;
  }
  if (v.reason === 'failures') {
    for (const f of failures) console.error(`FAIL ${f}`);
    console.error(`FAIL: ${failures.length} of ${blocks} mermaid blocks do not parse (mermaid ${MERMAID_VERSION}). Quote any label containing [ ] ( ) { } | or #, e.g. -->|"text [ID#n]"|`);
    return 1;
  }
  console.log(`PASS: all ${blocks} mermaid blocks in ${files.length} tracked markdown files parse (mermaid ${MERMAID_VERSION}, marked ${version('marked')})`);
  return 0;
}

// --selftest: each case asserts the exit code AND what was reported -- the source line a
// failure names, or the block count a pass found. The exit code alone cannot tell a gate
// that caught the defect from one that failed for another reason: several red cases here
// exit 1 whether or not the gate found the diagram, because a gate that finds nothing
// trips the vacuity guard. Red cases sit beside green ones -- two of them pairs,
// edge-label and closed-by-list-item -- so that a checker which fails
// everything cannot pass the green cases, and one which finds nothing cannot pass the red
// ones, which assert what was reported and not only the exit code.
async function selftest() {
  let bad = 0;
  const expect = async (desc, dirOrFiles, { exit, blocks, report, reason, includes, excludes }) => {
    const files = Array.isArray(dirOrFiles) ? dirOrFiles : walkMarkdown(path.join(FIXTURES, dirOrFiles));
    const root = path.dirname(files[0]);
    const r = await checkFiles(files, root);
    const v = verdict(r);
    const problems = [];
    if (v.exit !== exit) problems.push(`exit ${v.exit}, want ${exit}`);
    if (reason && v.reason !== reason) problems.push(`verdict ${v.reason}, want ${reason}`);
    if (blocks !== undefined && r.blocks !== blocks) problems.push(`${r.blocks} blocks, want ${blocks}`);
    if (report && !r.failures.some((f) => f.startsWith(report))) {
      problems.push(`no failure reported at ${report} (got: ${r.failures.join(' ; ') || 'none'})`);
    }
    if (includes && !r.failures.some((f) => f.includes(includes))) {
      problems.push(`no failure mentions "${includes}" (got: ${r.failures.join(' ; ') || 'none'})`);
    }
    if (excludes && r.failures.some((f) => f.includes(excludes))) {
      problems.push(`a failure wrongly mentions "${excludes}" (got: ${r.failures.join(' ; ')})`);
    }
    if (problems.length) { bad++; console.log(`FAIL ${desc}: ${problems.join('; ')}`); }
    else console.log(`ok ${desc}`);
  };

  // What is found, and what is not.
  await expect('an unquoted bracketed edge label is rejected, at its source line',
    'red-edge-label', { exit: 1, blocks: 1, report: 'page.md:9:' });
  await expect('the same label quoted is accepted',
    'green-edge-label', { exit: 0, blocks: 1 });
  await expect('a fence indented under a numbered list item is found and rejected',
    'red-indented', { exit: 1, blocks: 1, report: 'page.md:8:' });
  await expect('a fence inside a blockquote is found and rejected',
    'red-blockquote', { exit: 1, blocks: 1, report: 'page.md:5:' });
  await expect('a fence on a list-marker line is found and rejected',
    'red-list-marker', { exit: 1, blocks: 1, report: 'page.md:5:' });
  await expect('a diagram after a line opening with a backtick code span is found and rejected',
    'red-after-code-span', { exit: 1, blocks: 1, report: 'page.md:9:' });
  await expect('a mermaid fence quoted inside an outer fence is literal text, not a diagram',
    'green-nested', { exit: 0, blocks: 1 });
  await expect('a four-space-indented block after a paragraph is code, not a diagram',
    'green-indented-code', { exit: 0, blocks: 1 });
  await expect('a tilde fence and an info string with trailing words are both diagrams',
    'green-tilde-and-info', { exit: 0, blocks: 2 });
  await expect('an unclosed fence at the end of the file is still a diagram, and a valid one passes',
    'green-unclosed-at-eof', { exit: 0, blocks: 1 });
  await expect('a fence the next list item closes is a diagram, and a valid one passes',
    'green-closed-by-list-item', { exit: 0, blocks: 1 });
  await expect('an unclosed fence that swallows prose fails, and says it ran to the end of the file',
    'red-unclosed-swallows-prose', { exit: 1, blocks: 1, includes: 'never closed' });
  await expect('a broken fence its list item closes fails without claiming it ran to the end of the file',
    'red-closed-by-list-item', { exit: 1, blocks: 1, report: 'page.md:5:', excludes: 'never closed' });
  await expect('a tree with no mermaid block fails the vacuity guard',
    'red-no-blocks', { exit: 1, blocks: 0, reason: 'vacuous' });

  // Where a failure points, through everything mermaid removes before it counts lines.
  await expect('the line holds past whole-line %% comments',
    'red-line-comments', { exit: 1, blocks: 1, report: 'page.md:10:' });
  await expect('the line holds past frontmatter',
    'red-line-frontmatter', { exit: 1, blocks: 1, report: 'page.md:10:' });
  await expect('the line holds past an init directive',
    'red-line-directive', { exit: 1, blocks: 1, report: 'page.md:8:' });
  await expect('the line holds past a leading blank line',
    'red-line-leading-blank', { exit: 1, blocks: 1, report: 'page.md:8:' });
  await expect('the line holds past a decision node and a blank line, which flowchart collapses',
    'red-line-decision-node', { exit: 1, blocks: 1, report: 'page.md:8:' });
  await expect('the line holds past a shape node and two blank lines',
    'red-line-shape-syntax', { exit: 1, blocks: 1, report: 'page.md:8:' });
  await expect('the line holds when a comment sits directly above the failure',
    'red-line-after-comment', { exit: 1, blocks: 1, report: 'page.md:7:' });
  await expect('the line holds past a comment before frontmatter, which mermaid strips on a second pass',
    'red-line-comment-before-frontmatter', { exit: 1, blocks: 1, report: 'page.md:11:' });
  await expect('the line holds when mermaid rewrites an HTML attribute\'s quotes inside the context',
    'red-line-html-attribute', { exit: 1, blocks: 1, report: 'page.md:6:' });
  await expect('the line holds when the source writes single quotes inside the context',
    'red-line-single-quotes', { exit: 1, blocks: 1, report: 'page.md:6:' });
  await expect('a failure mermaid gives no location for names the fence line and says why',
    'red-no-location', { exit: 1, blocks: 1, report: 'page.md:3: (in the diagram opening here; mermaid printed no location)' });

  // locateError's refusals, driven directly: mermaid's ~40-character context almost never
  // repeats in a real diagram, so no fixture reliably reaches these branches.
  const unit = (desc, got, want) => {
    const ok = JSON.stringify(got) === JSON.stringify(want);
    if (!ok) { bad++; console.log(`FAIL ${desc}: got ${JSON.stringify(got)}, want ${JSON.stringify(want)}`); }
    else console.log(`ok ${desc}`);
  };
  const ctx = (c, col) => `Parse error on line 2:\n${c}\n${'-'.repeat(col)}^\nExpecting 'X', got 'Y'`;
  unit('a context found exactly once pins its line',
    locateError('flowchart TD\n    q -->|p [r]| s', ctx('...rt TD    q -->|p [r]| s', 18)), { line: 1 });
  unit('a context found twice is refused, not guessed',
    locateError('flowchart TD\n    q -->|p [r]| s\n    q -->|p [r]| s', ctx('q -->|p [r]| s', 8)),
    { reason: 'the failure\'s context occurs more than once' });
  unit('a context absent from the diagram is refused',
    locateError('flowchart TD\n    a --> b', ctx('...nothing like this at all', 10)),
    { reason: 'the failure\'s context is not in the diagram' });

  // CRLF is written here rather than committed, so no git line-ending setting can
  // normalise the case away before it runs.
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'check-mermaid-'));
  const crlf = path.join(tmp, 'page.md');
  fs.writeFileSync(crlf, ['# Red: CRLF line endings', '', '```mermaid', 'flowchart TD',
    '    a["x"]', '    a -->|see [AC#n]| b', '```', ''].join('\r\n'));
  await expect('a diagram in a CRLF file is found, at its source line',
    [crlf], { exit: 1, blocks: 1, report: 'page.md:6:' });
  fs.rmSync(tmp, { recursive: true, force: true });

  console.log(bad ? `SELFTEST FAIL (${bad} case(s))` : 'SELFTEST PASS');
  return bad ? 1 : 0;
}

const args = process.argv.slice(2);
if (args[0] === '--selftest' && args.length === 1) {
  process.exit(await selftest());
} else if (args.length === 0 || (args[0] === '--root' && args.length === 2)) {
  process.exit(await runRoot(args[1] ?? '.'));
} else {
  console.error('Usage: node scripts/mermaid/check-mermaid.mjs [--root <dir>] | --selftest');
  process.exit(2);
}

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
// WHERE IT POINTS. A failure names the SOURCE-FILE line. mermaid numbers its errors from
// its own preprocessed text, after it has removed frontmatter, %%{...}%% directives, whole-
// line %% comments and leading whitespace (mermaid's preprocessDiagram); mapErrorLine
// replays exactly those removals, so the line holds even in a diagram that uses them. Where
// a line cannot be mapped, it says so and names the fence line rather than guessing.
//
// THE VERSION PIN. GitHub does not publish the mermaid version it serves. The failure
// above reproduced identically on mermaid 10.9.8, 11.17.2 and 12.0.0, so the pin is the
// mature 11.x line. package.json pins exact versions and package-lock.json is committed,
// so neither the parser nor the lexer can change under the gate between two runs; moving
// either is an edit to package.json plus a regenerated lockfile, taken deliberately -- and
// mapErrorLine's fixtures are what will say if a new mermaid preprocesses differently.
//
// SCOPE. Tracked markdown only (`git ls-files`), because a tracked file is what GitHub
// renders -- which also leaves out every git worktree copy under the ignored .worktrees/.
// The one subtree excluded is this gate's own negative fixtures, scripts/fixtures/mermaid/,
// whose red cases are broken on purpose.
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
  const walk = (tokens, firstLine) => {
    let line = firstLine;
    for (const t of tokens) {
      if (t.type === 'code' && t.codeBlockStyle !== 'indented'
          && (t.lang ?? '').trim().split(/\s+/)[0] === 'mermaid') {
        blocks.push({ fenceLine: line, src: t.text, unclosed: !closesItsFence(t.raw) });
      } else if (t.type === 'blockquote') {
        walk(t.tokens, line);
      } else if (t.type === 'list') {
        let itemLine = line;
        for (const item of t.items) { walk(item.tokens, itemLine); itemLine += newlines(item.raw); }
      }
      line += newlines(t.raw);
    }
  };
  // marked normalises CRLF and CR to LF itself; the selftest's CRLF case pins that.
  walk(marked.lexer(text), 1);
  return blocks;
}

// A fenced block that reaches the end of its container with no closing fence: CommonMark
// runs it to the end, so GitHub draws the rest of the file as the diagram.
function closesItsFence(raw) {
  const lines = raw.replace(/\n+$/, '').split('\n');
  const open = lines[0].trim().match(/^(`{3,}|~{3,})/);
  if (!open || lines.length < 2) return false;
  const close = new RegExp(`^${open[1][0] === '`' ? '`' : '~'}{${open[1].length},}\\s*$`);
  return close.test(lines[lines.length - 1].trim());
}

// mermaid's preprocessDiagram, reproduced for its line-removing steps only (cleanupText's
// attribute-quote rewrite never adds or removes a line). The regexes are mermaid 11.17.2's
// own. Then match the surviving lines back to the block in order, comparing trimmed text,
// since trimStart also strips the first survivor's indentation. Returns the 0-based index
// of the block line mermaid called `n`, or null where no clean mapping exists.
const FRONTMATTER = /^([^\S\n\r]*)-{3}\s*[\n\r](.*?)[\n\r]\1-{3}\s*[\n\r]+/s;
const DIRECTIVE = /%{2}{\s*(?:(\w+)\s*:|(\w+))\s*(?:(\w+)|((?:(?!}%{2}).|\r?\n)*))?\s*(?:}%{2})?/gi;
function mapErrorLine(blockText, n) {
  const original = blockText.replace(/\r\n?/g, '\n');
  const fm = original.match(FRONTMATTER);
  let code = fm ? original.slice(fm[0].length) : original;
  code = code.replace(DIRECTIVE, '');
  code = code.replace(/^\s*%%(?!{)[^\n]+\n?/gm, '').trimStart();
  const survivors = code.split('\n');
  const lines = original.split('\n');
  if (n < 1 || n > survivors.length) return null;
  let p = 0;
  for (let k = 0; k < n; k++) {
    const want = survivors[k].trim();
    while (p < lines.length && lines[p].trim() !== want) p++;
    if (p >= lines.length) return null;
    if (k === n - 1) return p;
    p++;
  }
  return null;
}

// Check one set of files. Returns { blocks, failures }, each failure "file:line: message".
async function checkFiles(files, displayRoot) {
  let blocks = 0;
  const failures = [];
  for (const file of files) {
    const rel = path.relative(displayRoot, file);
    for (const b of extractBlocks(fs.readFileSync(file, 'utf8'))) {
      blocks++;
      if (b.unclosed) {
        failures.push(`${rel}:${b.fenceLine}: unclosed \`\`\`mermaid fence -- GitHub treats the rest of the file as the diagram`);
        continue;
      }
      try {
        await mermaid.parse(b.src);
      } catch (e) {
        const msg = String(e?.message ?? e);
        const detail = msg.split('\n').filter(Boolean).slice(0, 3).join(' | ');
        const m = msg.match(/on line (\d+)/);
        const idx = m ? mapErrorLine(b.src, Number(m[1])) : null;
        failures.push(idx === null
          ? `${rel}:${b.fenceLine}: (in the diagram opening here${m ? `; mermaid's line ${m[1]}` : ''}) ${detail}`
          : `${rel}:${b.fenceLine + 1 + idx}: ${detail}`);
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
// trips the vacuity guard. The cases are paired red/green so that a checker which fails
// everything, or finds nothing, cannot pass both halves.
async function selftest() {
  let bad = 0;
  const expect = async (desc, dirOrFiles, { exit, blocks, report, reason }) => {
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
  await expect('an unclosed mermaid fence is rejected',
    'red-unclosed', { exit: 1, blocks: 1, report: 'page.md:5: unclosed' });
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

#!/usr/bin/env node
// check-mermaid.mjs -- every ```mermaid block in every tracked markdown file must parse.
//
// WHY THIS GATE EXISTS. GitHub draws a ```mermaid fence as a diagram, and where the
// diagram does not parse it shows "Unable to render rich display" and a parse error in
// its place. Nothing else in this repository reads mermaid, so a broken diagram is
// invisible to every other gate. That is not hypothetical: plugins/product-workflows/
// docs/workflow.md shipped from product-workflows 3.0.0 onward with five unquoted edge
// labels carrying `[BR#n]`, `[CG#n]/[DG#n]` and `[AC#n]/[FR#n]` -- mermaid reads a `[`
// inside an edge label as the start of a node shape -- and it was found by a person
// opening the page on GitHub, not by anything that runs on a push.
//
// WHAT IT CHECKS, AND WHAT IT DOES NOT. It runs mermaid's own parser over every block.
// Parsing is the failure GitHub reports, and the gate was calibrated against that report
// before it shipped: on the broken page it reproduces GitHub's exact error (the same
// line, the same caret, "got 'SQS'"), and across this tree it agreed block for block with
// a real headless render (mermaid-cli, a browser) -- every block that rendered parsed, and
// the one that did not render was the one that did not parse. It does NOT render. A
// diagram that parses and then fails at layout would pass. That class did not occur on
// this tree, and a real render needs a browser in CI, which this gate does not carry.
//
// THE VERSION PIN. GitHub does not publish the mermaid version it serves. The failure
// above reproduced identically on mermaid 10.9.8, 11.17.2 and 12.0.0, so the pin is the
// mature 11.x line. package.json pins exact versions and package-lock.json is committed,
// so the parser cannot change under the gate between two runs; moving to a newer mermaid
// is an edit to package.json plus a regenerated lockfile, taken deliberately.
//
// SCOPE. Tracked markdown only (`git ls-files`), because a tracked file is what GitHub
// renders -- which also leaves out every git worktree copy under the ignored .worktrees/,
// the problem check-id-grammar.sh has to exclude by hand. The one subtree excluded is
// this gate's own negative fixtures, scripts/fixtures/mermaid/, whose red cases are
// broken on purpose.
//
// Usage: node scripts/mermaid/check-mermaid.mjs [--root <dir>]   (default --root .)
//        node scripts/mermaid/check-mermaid.mjs --selftest
// Exit:  0 every block parses; 1 a block does not, or no block was found; 2 usage error.

import { JSDOM } from 'jsdom';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
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
const MERMAID_VERSION = JSON.parse(
  fs.readFileSync(path.join(HERE, 'node_modules/mermaid/package.json'), 'utf8')).version;

// A CommonMark fence state machine, not a regex over the file. A ```mermaid line inside
// an outer ````markdown example is literal text that GitHub does not draw, and a regex
// extractor would try to parse it. Fences open with 3+ backticks or tildes; a fence
// closes on the same character repeated at least as many times, and nothing else.
function extractBlocks(text) {
  const lines = text.split('\n');
  const blocks = [];
  let open = null; // { char, len, isMermaid, fenceLine, body }
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (open === null) {
      const m = line.match(/^( *)(`{3,}|~{3,})\s*([^`\s]*)/);
      if (!m) continue;
      open = { char: m[2][0], len: m[2].length, indent: m[1].length,
               isMermaid: m[3] === 'mermaid', fenceLine: i + 1, body: [] };
      continue;
    }
    const close = line.match(/^\s*(`{3,}|~{3,})\s*$/);
    if (close && close[1][0] === open.char && close[1].length >= open.len) {
      if (open.isMermaid) blocks.push({ fenceLine: open.fenceLine, src: open.body.join('\n') });
      open = null;
      continue;
    }
    // CommonMark removes up to the opening fence's indentation from each content line.
    if (open.isMermaid) open.body.push(line.replace(new RegExp(`^ {0,${open.indent}}`), ''));
  }
  if (open && open.isMermaid) blocks.push({ fenceLine: open.fenceLine, unclosed: true });
  return blocks;
}

// Check one set of files. Returns { blocks, failures }, each failure "file:line: message",
// where line is the SOURCE-FILE line -- mermaid numbers its errors from the diagram's own
// first line, which nobody can find in a thousand-line page.
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
        const m = msg.match(/on line (\d+)/);
        const line = m ? b.fenceLine + Number(m[1]) : b.fenceLine;
        const detail = msg.split('\n').filter(Boolean).slice(0, 3).join(' | ');
        failures.push(`${rel}:${line}: ${detail}`);
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
  console.log(`PASS: all ${blocks} mermaid blocks in ${files.length} tracked markdown files parse (mermaid ${MERMAID_VERSION})`);
  return 0;
}

// --selftest: each case asserts the exit code AND what was reported -- the file and the
// source line a failure names, or the block count a pass found. The exit code alone
// cannot tell a gate that caught the defect from one that failed for another reason, and
// the cases are paired red/green so that a checker which fails everything, or finds
// nothing, cannot pass both halves.
async function selftest() {
  let bad = 0;
  const expect = async (desc, dir, { exit, blocks, report, reason }) => {
    const root = path.join(FIXTURES, dir);
    const r = await checkFiles(walkMarkdown(root), root);
    const v = verdict(r);
    const got = v.exit;
    const problems = [];
    if (reason && v.reason !== reason) problems.push(`verdict ${v.reason}, want ${reason}`);
    if (got !== exit) problems.push(`exit ${got}, want ${exit}`);
    if (blocks !== undefined && r.blocks !== blocks) problems.push(`${r.blocks} blocks, want ${blocks}`);
    if (report && !r.failures.some((f) => f.startsWith(report))) {
      problems.push(`no failure reported at ${report} (got: ${r.failures.join(' ; ') || 'none'})`);
    }
    if (problems.length) { bad++; console.log(`FAIL ${desc}: ${problems.join('; ')}`); }
    else console.log(`ok ${desc}`);
  };

  await expect('an unquoted bracketed edge label is rejected, at its source line',
    'red-edge-label', { exit: 1, blocks: 1, report: 'page.md:9:' });
  await expect('the same label quoted is accepted',
    'green-edge-label', { exit: 0, blocks: 1 });
  await expect('a broken diagram in an indented fence is found and rejected',
    'red-indented', { exit: 1, blocks: 1, report: 'page.md:8:' });
  await expect('a mermaid fence quoted inside an outer fence is literal text, not a diagram',
    'green-nested', { exit: 0, blocks: 1 });
  await expect('an unclosed mermaid fence is rejected',
    'red-unclosed', { exit: 1, blocks: 1, report: 'page.md:5: unclosed' });
  await expect('a tree with no mermaid block fails the vacuity guard',
    'red-no-blocks', { exit: 1, blocks: 0, reason: 'vacuous' });

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

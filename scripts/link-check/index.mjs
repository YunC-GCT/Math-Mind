/**
 * scripts/link-check/index.mjs
 *
 * Walks docs/ and verifies that every markdown link `[text](url)` points
 * to an existing file (relative) or external URL (skipped — no network check).
 *
 * Mirrors scripts/naming-lint/'s structure (--json output, exit codes,
 * frozen config, unit-tested pure helpers).
 *
 * Usage:
 *   node scripts/link-check/index.mjs
 *   node scripts/link-check/index.mjs --json
 *   node scripts/link-check/index.mjs docs         # custom root
 *
 * Exit codes:
 *   0 = all links resolve
 *   1 = one or more broken links
 *   2 = config / parser error
 */

import { readdirSync, statSync, existsSync, readFileSync } from 'node:fs';
import { join, relative, dirname, extname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { extractLinks, classifyLink, resolveRelativePath } from './link-parser.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = join(__dirname, '..', '..');

const DEFAULT_ROOTS = ['docs', 'CONTEXT.md', 'AGENTS.md', 'README.md'];
const SKIP_DIRS = new Set(['node_modules', '.git', '_fetched', '__snapshots__', '__generated__', 'vendor']);

// ----------------------------------------------------------------------------
// Walker
// ----------------------------------------------------------------------------

function walk(rootPath, onFile) {
  function visit(p) {
    let st;
    try { st = statSync(p); } catch { return; }
    if (st.isDirectory()) {
      const base = p.replace(REPO_ROOT + '\\', '').replace(REPO_ROOT + '/', '').split(/[/\\]/).pop();
      if (SKIP_DIRS.has(base)) return;
      let entries;
      try { entries = readdirSync(p); } catch { return; }
      for (const child of entries) {
        visit(join(p, child));
      }
    } else if (st.isFile() && p.endsWith('.md')) {
      onFile(p);
    }
  }
  visit(rootPath);
}

// ----------------------------------------------------------------------------
// Link checker
// ----------------------------------------------------------------------------

function checkLinksInFile(absPath, relPath, broken) {
  let content;
  try { content = readFileSync(absPath, 'utf8'); } catch { return; }

  const links = extractLinks(content, relPath);
  for (const link of links) {
    const cls = classifyLink(link.href, relPath);
    if (cls.kind === 'external') continue; // skip external URLs (no network)
    if (cls.kind === 'anchor') continue;   // skip in-page anchors (not validated)

    // File link
    const resolved = resolveRelativePath(relPath, cls.path);
    const absTarget = join(REPO_ROOT, resolved);
    if (!existsSync(absTarget)) {
      broken.push({
        sourceFile: relPath,
        line: link.line,
        column: link.column,
        linkText: link.text,
        href: link.href,
        resolvedPath: resolved,
        reason: 'target does not exist',
      });
    }
  }
}

// ----------------------------------------------------------------------------
// Main
// ----------------------------------------------------------------------------

function main() {
  const args = process.argv.slice(2);
  const jsonMode = args.includes('--json');
  const positional = args.filter((a) => !a.startsWith('--') && a.length > 0);
  const scanRoots = positional.length > 0 ? positional : DEFAULT_ROOTS;

  const broken = [];

  for (const root of scanRoots) {
    const abs = join(REPO_ROOT, root);
    if (!existsSync(abs)) {
      // File (not dir) — single-file mode
      if (extname(root) === '.md') {
        const rel = relative(REPO_ROOT, abs);
        checkLinksInFile(abs, rel, broken);
      }
      continue;
    }
    const st = statSync(abs);
    if (st.isFile()) {
      const rel = relative(REPO_ROOT, abs);
      checkLinksInFile(abs, rel, broken);
    } else {
      walk(abs, (file) => {
        const rel = relative(REPO_ROOT, file);
        checkLinksInFile(file, rel, broken);
      });
    }
  }

  if (jsonMode) {
    const report = {
      tool: 'link-check',
      version: '0.1.0',
      timestamp: new Date().toISOString(),
      roots: scanRoots,
      passed: broken.length === 0,
      brokenCount: broken.length,
      broken: broken.map((b) => ({
        sourceFile: b.sourceFile,
        line: b.line,
        column: b.column,
        linkText: b.linkText,
        href: b.href,
        resolvedPath: b.resolvedPath,
        reason: b.reason,
      })),
    };
    console.log(JSON.stringify(report, null, 2));
    process.exit(broken.length === 0 ? 0 : 1);
  }

  if (broken.length === 0) {
    console.log(`OK: link-check passed (0 broken links across ${scanRoots.length} root(s))`);
    process.exit(0);
  }

  console.error(`FAIL: link-check found ${broken.length} broken link(s):\n`);
  for (const b of broken) {
    console.error(`  ${b.sourceFile}:${b.line}:${b.column}`);
    console.error(`    text:  ${b.linkText}`);
    console.error(`    href:  ${b.href}`);
    console.error(`    → ${b.resolvedPath} (${b.reason})`);
    console.error('');
  }
  process.exit(1);
}

main();
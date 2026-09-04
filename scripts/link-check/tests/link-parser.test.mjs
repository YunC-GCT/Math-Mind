/**
 * scripts/link-check/tests/link-parser.test.mjs
 *
 * Unit tests for the link-parser helpers. No filesystem access.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { extractLinks, classifyLink, resolveRelativePath } from '../link-parser.mjs';

test('extractLinks handles single inline link', () => {
  const md = 'See [docs](docs/intro.md) for more.';
  const links = extractLinks(md, 'test.md');
  assert.equal(links.length, 1);
  assert.equal(links[0].text, 'docs');
  assert.equal(links[0].href, 'docs/intro.md');
  assert.equal(links[0].line, 1);
});

test('extractLinks handles multiple links on one line', () => {
  const md = 'See [a](a.md) and [b](b.md) and [c](c.md).';
  const links = extractLinks(md);
  assert.equal(links.length, 3);
  assert.deepEqual(links.map((l) => l.href), ['a.md', 'b.md', 'c.md']);
});

test('extractLinks handles multi-line markdown', () => {
  const md = [
    'line 1',
    'line 2 [link](file.md)',
    'line 3',
    'line 4 [another](other.md)',
  ].join('\n');
  const links = extractLinks(md);
  assert.equal(links.length, 2);
  assert.equal(links[0].line, 2);
  assert.equal(links[1].line, 4);
});

test('extractLinks returns empty array for no links', () => {
  const md = 'no links here, just text';
  const links = extractLinks(md);
  assert.equal(links.length, 0);
});

test('extractLinks handles link with title', () => {
  const md = '[text](url.md "title text")';
  const links = extractLinks(md);
  assert.equal(links.length, 1);
  assert.equal(links[0].href, 'url.md');
  assert.equal(links[0].text, 'text');
});

test('extractLinks handles URLs in code spans (should match)', () => {
  // We DO match links in code spans — caller is responsible for filtering
  // if they want to. Documented behavior.
  const md = 'Use `[link](file.md)` inline.';
  const links = extractLinks(md);
  assert.equal(links.length, 1);
  assert.equal(links[0].href, 'file.md');
});

test('classifyLink identifies external URLs', () => {
  const cls = classifyLink('https://example.com', 'doc.md');
  assert.equal(cls.kind, 'external');
  assert.equal(cls.url, 'https://example.com');
});

test('classifyLink identifies http:// as external', () => {
  const cls = classifyLink('http://example.com', 'doc.md');
  assert.equal(cls.kind, 'external');
});

test('classifyLink identifies mailto: as external', () => {
  const cls = classifyLink('mailto:foo@example.com', 'doc.md');
  assert.equal(cls.kind, 'external');
});

test('classifyLink identifies anchor links', () => {
  const cls = classifyLink('#section-3', 'doc.md');
  assert.equal(cls.kind, 'anchor');
  assert.equal(cls.anchor, 'section-3');
});

test('classifyLink identifies relative file links', () => {
  const cls = classifyLink('foo/bar.md', 'doc.md');
  assert.equal(cls.kind, 'file');
  assert.equal(cls.path, 'foo/bar.md');
});

test('classifyLink splits file path from fragment', () => {
  const cls = classifyLink('foo/bar.md#section-1', 'doc.md');
  assert.equal(cls.kind, 'file');
  assert.equal(cls.path, 'foo/bar.md');
  assert.equal(cls.anchor, 'section-1');
});

test('resolveRelativePath handles same directory', () => {
  const r = resolveRelativePath('docs/specs/003.md', '002.md');
  assert.equal(r, 'docs/specs/002.md');
});

test('resolveRelativePath handles parent reference', () => {
  const r = resolveRelativePath('docs/specs/003.md', '../adr/0001.md');
  assert.equal(r, 'docs/adr/0001.md');
});

test('resolveRelativePath handles current directory', () => {
  const r = resolveRelativePath('docs/specs/003.md', './sibling.md');
  assert.equal(r, 'docs/specs/sibling.md');
});

test('resolveRelativePath handles top-level file (no dir)', () => {
  const r = resolveRelativePath('CONTEXT.md', 'docs/intro.md');
  assert.equal(r, 'docs/intro.md');
});

test('resolveRelativePath handles multiple parent references', () => {
  const r = resolveRelativePath('docs/specs/sub/003.md', '../../adr/0001.md');
  assert.equal(r, 'docs/adr/0001.md');
});

test('resolveRelativePath handles absolute path inside repo', () => {
  // An absolute path starting with / is unusual but the function
  // should not break — it just concatenates. Most markdown links
  // are relative, not absolute.
  const r = resolveRelativePath('docs/003.md', '/docs/intro.md');
  // /docs/intro.md splits to ['', 'docs', 'intro.md'], joined with source 'docs' → 'docs/docs/intro.md'
  // Documented behavior; unusual usage.
  assert.equal(r, 'docs/docs/intro.md');
});
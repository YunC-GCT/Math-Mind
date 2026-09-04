/**
 * scripts/link-check/link-parser.mjs
 *
 * Pure helpers for extracting markdown links from text. No filesystem access.
 * Testable in isolation.
 */

/**
 * Extract all markdown links from a markdown string.
 * Handles both inline `[text](url)` and reference-style `[text][ref]` forms
 * (we only resolve inline for now; reference-style is left as a TODO).
 *
 * Returns an array of { text, href, line, column } objects.
 */
export function extractLinks(markdown, sourceFile = '<inline>') {
  const links = [];
  const lines = markdown.split('\n');
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    // Match [text](url) — text can contain anything except unescaped ]
    // URL can be relative, absolute, or a fragment
    const re = /\[([^\]]+)\]\(([^)\s]+)(?:\s+"[^"]*")?\)/g;
    let m;
    while ((m = re.exec(line)) !== null) {
      links.push({
        text: m[1],
        href: m[2],
        line: i + 1,
        column: m.index + 1,
        sourceFile,
      });
    }
  }
  return links;
}

/**
 * Resolve a link href relative to a source file's directory.
 * Returns:
 *   { kind: 'external', url }   for http(s)://, mailto:, etc.
 *   { kind: 'anchor', anchor }  for #fragment
 *   { kind: 'file',    path }   for relative file
 */
export function classifyLink(href, sourceFile) {
  if (href.startsWith('http://') || href.startsWith('https://')) {
    return { kind: 'external', url: href };
  }
  if (href.startsWith('mailto:') || href.startsWith('ftp://')) {
    return { kind: 'external', url: href };
  }
  if (href.startsWith('#')) {
    return { kind: 'anchor', anchor: href.slice(1) };
  }
  // Otherwise: relative path (may have a #fragment appended)
  const [path, anchor] = href.split('#');
  return { kind: 'file', path, anchor };
}

/**
 * Resolve a relative path against a source file's directory.
 * E.g. sourceFile = 'docs/specs/003-foo.md', linkPath = '../adr/0001-bar.md'
 *   → 'docs/adr/0001-bar.md'
 */
export function resolveRelativePath(sourceFile, linkPath) {
  // Normalize Windows backslashes to forward slashes (path.relative on
  // Windows uses \ which breaks the split-based algorithm below).
  const src = sourceFile.replace(/\\/g, '/');
  const link = linkPath.replace(/\\/g, '/');

  // Get directory of source file
  const lastSlash = src.lastIndexOf('/');
  const sourceDir = lastSlash >= 0 ? src.slice(0, lastSlash) : '';
  if (!sourceDir) return link;

  // Manual path join + normalize (no node:path dependency)
  const parts = sourceDir.split('/').concat(link.split('/'));
  const result = [];
  for (const part of parts) {
    if (part === '' || part === '.') continue;
    if (part === '..') {
      result.pop();
    } else {
      result.push(part);
    }
  }
  return result.join('/');
}
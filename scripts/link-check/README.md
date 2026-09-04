# link-check

> **Mirrors the structure of [`scripts/naming-lint/`](../naming-lint/)** — a single-purpose Node tool, pure-helper module, unit tests, --json output for CI.

## Purpose

Walks `docs/` (or any directory of `.md` files) and verifies that every markdown link `[text](url)` points to an existing file.

Skips:
- External URLs (`http://`, `https://`, `mailto:`, `ftp://`) — no network check
- In-page anchors (`#section-1`) — not validated

Reports:
- Broken relative links
- Source file + line + column
- Resolved absolute path (for debugging)
- Reason (e.g. "target does not exist")

## Usage

```bash
# Default: scan docs/, CONTEXT.md, AGENTS.md, README.md
node scripts/link-check/index.mjs

# Custom root
node scripts/link-check/index.mjs docs/specs

# JSON output (for CI / pre-commit hook)
node scripts/link-check/index.mjs --json

# Run unit tests
node --test scripts/link-check/tests/*.test.mjs
```

Exit codes:
- `0` = all links resolve
- `1` = one or more broken links
- `2` = config / parser error

## Skipped paths

Always skipped:
- `node_modules/`, `.git/`, `_fetched/`, `__snapshots__/`, `__generated__/`, `vendor/`
- Non-`.md` files

## Output format

### Human-readable

```
FAIL: link-check found 2 broken link(s):

  docs/specs/003-foo.md:42:5
    text:  broken link
    href:  ../adr/0000-missing.md
    → docs/adr/0000-missing.md (target does not exist)

  ...
```

### JSON (`--json`)

```json
{
  "tool": "link-check",
  "version": "0.1.0",
  "timestamp": "2026-09-04T...",
  "roots": ["docs", "CONTEXT.md", "AGENTS.md", "README.md"],
  "passed": false,
  "brokenCount": 1,
  "broken": [
    {
      "sourceFile": "docs/specs/003-foo.md",
      "line": 42,
      "column": 5,
      "linkText": "broken link",
      "href": "../adr/0000-missing.md",
      "resolvedPath": "docs/adr/0000-missing.md",
      "reason": "target does not exist"
    }
  ]
}
```

## Known limitations

- **Reference-style links** (`[text][ref]` with `[ref]: url` elsewhere) are not resolved. Only inline `[text](url)` is matched.
- **Links inside code spans** (backticks) are matched (we don't filter). This is documented behavior; filter if needed.
- **External URLs** are not checked (no network call). If a `https://` link is broken, this tool won't catch it.
- **In-page anchors** (`#section`) are not validated against actual heading IDs.

## Adding rules

- New link kinds (e.g. `tel:`): add to `classifyLink()` in `link-parser.mjs`
- New file extensions to scan (e.g. `.mdx`): update the `.endsWith('.md')` check in `walk()`
- New skip patterns: update `SKIP_DIRS` in `index.mjs` (or move to config)

## When to update this file

Same as `naming-lint/README.md` — when a rule is added, removed, or changed; bump the version.
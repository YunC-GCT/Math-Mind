# naming-lint

> **Authoritative spec:** [`docs/style/naming-conventions.md`](../../docs/style/naming-conventions.md)

Lints file and directory names against the project's naming spec. Runs as a Node script (no external dependencies — uses only `node:fs`, `node:path`).

## Usage

```bash
# Default: scan docs/ and scripts/ from repo root
node scripts/naming-lint/index.mjs

# Custom roots
node scripts/naming-lint/index.mjs docs scripts frontend backend

# Run unit tests
node --test scripts/naming-lint/tests/*.test.mjs

# Or via npm (if you link it locally)
npm --prefix scripts/naming-lint test
```

Exit codes:
- `0` = no violations
- `1` = one or more violations found

## What it checks

| Rule | Where it applies |
|---|---|
| **No spaces** in any file/dir name | everywhere |
| **kebab-case** for `.md` `.json` `.json5` `.yml` `.yaml` `.toml` `.ts` `.mjs` `.cjs` `.js` | anywhere |
| **snake_case** for `.py` | anywhere |
| **PascalCase** for `.tsx` (component basenames) | anywhere |
| **ADR prefix** `NNNN-{slug}.md` | `docs/adr/*.md` (except `index.md`) |
| **Spec prefix** `NNN-{slug}.md` | `docs/specs/*.md` (except `index.md`) |
| **Research date suffix** `-YYYY-MM-DD.md` | `docs/research/*.md` (except `index.md`) |
| **No `.html` in `docs/`** | `.html` files in `docs/` are gitignored renders, never source |

## Skipped paths

Always skipped (third-party / build outputs / agent metadata):
- `node_modules/`, `oh_modules/`, `.hvigor/`, `build/`, `dist/`
- `.git/`, `.reasonix/`, `.appanalyzer/`
- `docs/research/_fetched/` (raw fetched material, gitignored)

## Output format

When violations are found:

```
FAIL: naming-lint found 3 violation(s):

  [md-kebab] (2)
    docs/2026-07-20/some File.md
        → .md filename must be kebab-case
    docs/agents/someThing.md
        → .md filename must be kebab-case

  [py-snake] (1)
    backend/SomeFile.py
        → .py filename must be snake_case
```

## Adding rules

Edit `index.mjs` to add new rules; add unit tests for new checker functions in `tests/rule-checkers.test.mjs`.

Always update `docs/style/naming-conventions.md` first, then the linter — the doc is the source of truth, the linter is the enforcement.
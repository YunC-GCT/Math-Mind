# naming-lint

> **Authoritative spec:** [`docs/style/naming-conventions.md`](../../docs/style/naming-conventions.md)

Lints file and directory names against the project's naming spec. Runs as a Node script (no external dependencies — uses only `node:fs`, `node:path`).

## Usage

```bash
# Default: scan docs/ and scripts/ from repo root
node scripts/naming-lint/index.mjs

# Custom roots
node scripts/naming-lint/index.mjs docs scripts frontend backend

# JSON output (for CI / pre-commit hook integration)
node scripts/naming-lint/index.mjs --json docs scripts

# Run unit tests
node --test scripts/naming-lint/tests/*.test.mjs

# Or via npm
npm --prefix scripts/naming-lint test
```

Exit codes:
- `0` = no violations
- `1` = one or more violations found

Flags:
- `--json` — emit machine-readable JSON to stdout (errors/warnings go to stderr)

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
- Files named `README.md` (UPPERCASE top-level index allowed in any doc dir)
- Files starting with `_` (scaffolds, e.g. `_template.mjs`)

## Output formats

### Human-readable (default)

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

### JSON (`--json`)

```json
{
  "tool": "naming-lint",
  "version": "0.1.0",
  "timestamp": "2026-09-04T04:57:06.028Z",
  "roots": ["docs", "scripts"],
  "passed": true,
  "violationCount": 0,
  "violations": []
}
```

On failure, `violations` is an array of:

```json
{
  "path": "docs/some File.md",
  "name": "some File.md",
  "rule": "no-spaces",
  "message": "file/dir name must not contain whitespace"
}
```

### CI integration (GitHub Actions)

```yaml
- name: naming-lint
  run: |
    if ! node scripts/naming-lint/index.mjs --json docs scripts > /tmp/lint.json; then
      cat /tmp/lint.json | jq -r '.violations[] | "❌ \(.path) [\(.rule)]: \(.message)"'
      exit 1
    fi
```

### Pre-commit hook (Node-based, cross-platform)

```bash
# Install once (registers .git/hooks/pre-commit)
node scripts/naming-lint/install-hook.mjs

# Now every commit is gated by naming-lint.
# Skip for a single commit:
git commit --no-verify -m "skipping lint"
```

The hook script (`install-hook.mjs`) is platform-agnostic — works on Windows, macOS, Linux.

## Adding rules

Edit `index.mjs` to add new rules; add unit tests for new checker functions in `tests/rule-checkers.test.mjs`.

Always update `docs/style/naming-conventions.md` first, then the linter — the doc is the source of truth, the linter is the enforcement.

## When to add an exception

If a file legitimately cannot follow the spec (e.g. third-party file you cannot rename, legacy file pending migration):

1. Add the path to a `SKIP_LIST` constant in `index.mjs` (not committed unless the exception is permanent)
2. Or use `.naminglintignore` (TODO: not yet implemented) — `.gitignore`-style exclusion
3. **Don't add project-wide exclusions** — exceptions should be narrow, with a comment explaining why

For temporary exceptions during a migration, prefer fixing the file rather than excluding it.
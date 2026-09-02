#!/usr/bin/env bash
# lint-arkts-ast.sh — Unix wrapper for arkts-lint v0.3 (AST-based)
# Usage: scripts/lint-arkts-ast.sh              (default flags)
#        scripts/lint-arkts-ast.sh --json      (JSON mode)
#
# Exit code mirrors node exit: 0 = clean, 1 = errors

set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
node "$DIR/arkts-lint/index.mjs" "$@"
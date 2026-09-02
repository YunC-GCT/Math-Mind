#!/usr/bin/env bash
# lint-arkts.sh — Unix convenience wrapper for ArkTS 1.1 strict lint
# Usage: scripts/lint-arkts.sh              (default flags)
#        scripts/lint-arkts.sh --json      (JSON mode)
#
# Exit code mirrors node exit: 0 = clean, 1 = errors

set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
node "$DIR/audit-arkts-strict.mjs" "$@"
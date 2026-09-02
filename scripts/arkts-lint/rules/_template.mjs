/**
 * rules/_template.mjs — Copy this file as a starting point for new rules.
 *
 * Naming convention: <rule-id>.mjs (e.g. arkts-no-any-unknown.mjs)
 * Location: rules/official/ for ArkTS strict-mode; rules/project/ for project preferences.
 *
 * Required exports (default object):
 *   id        — unique string, must match filename
 *   code      — '10605xxx' for ArkTS rules, or 'project-pref' for project rules
 *   severity  — 'error' (blocks CI) | 'warn' (informational)
 *   title     — short human-readable summary
 *   fixHint   — suggestion for fixing the violation
 *   matches   — array of AST node types this rule listens to
 *   check     — (node, parent, ctx) → boolean. true = violation
 *
 * Optional:
 *   enabled   — defaults to true; set false to keep rule defined but disabled
 *   requiresTypeChecker — — true if rule needs TypeScript compiler API (v2.1+)
 */

import { walk } from '../ast-utils/walk.mjs';

/** Optional helper: skip if in comment. AST doesn't put keywords in comments by default,
 * but if your rule needs to, use ctx.locator.snippet() to inspect the source. */

export default {
  id: 'rule-id-here',
  code: '00000000',          // update to real ArkTS code
  severity: 'error',         // or 'warn'
  title: 'Short title here',
  fixHint: 'Suggested fix',

  /** AST node types that trigger check() — used by the engine for fast filtering. */
  matches: ['Identifier'],

  /**
   * Check a single AST node for violation.
   * @param {object} node — the matched AST node
   * @param {object} parent — parent AST node (may be null at root)
   * @param {object} ctx — { locator, sourceCode, file }
   * @returns {boolean} true = violation
   */
  check(node, parent, ctx) {
    // ... AST inspection here
    return false;
  },
};

// Re-export walk so rule authors can use it without an extra import.
export { walk };
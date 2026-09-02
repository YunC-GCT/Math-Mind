/**
 * run-rule.mjs — Test helper: parse a .ets source, apply a rule, return violations.
 *
 * Used by the test suite to verify each rule's behavior.
 *
 * Note: parser is imported statically (not dynamically) so the test runner
 * doesn't have async-loading issues.
 */

import { preprocessArkUI } from '../parser/index.mjs';
import { parse as tsParse } from '@typescript-eslint/parser';

/**
 * Run a single rule against a source string and return violations.
 *
 * @param {object} rule - Rule module (default export)
 * @param {string} source - .ets source code
 * @param {string} filename - Virtual filename for the source
 * @returns {Array<{ line: number, col: number, snippet: string }>}
 */
export function runRuleOnSource(rule, source, filename = '<test>') {
  const violations = [];
  const preprocessed = preprocessArkUI(source);
  let ast;
  try {
    ast = tsParse(preprocessed, {
      ecmaVersion: 'latest', sourceType: 'module',
      ecmaFeatures: { decorators: true, jsx: true },
      range: true, loc: true, errorRecovery: true,
      errorOnUnknownASTType: false, loggerFn: false,
    });
  } catch (e) {
    return [{ line: 0, col: 0, snippet: '', parseError: e.message }];
  }
  // Build parent map
  const parentMap = new WeakMap();
  (function walk(node, parent) {
    if (parent) parentMap.set(node, parent);
    for (const key of Object.keys(node)) {
      const value = node[key];
      if (Array.isArray(value)) {
        for (const child of value) {
          if (child && typeof child.type === 'string') walk(child, node);
        }
      } else if (value && typeof value === 'object' && typeof value.type === 'string') {
        walk(value, node);
      }
    }
  })(ast, null);
  // Apply rule
  (function walk2(node, parent) {
    if (rule.matches.includes(node.type)) {
      try {
        if (rule.check(node, parent, { sourceCode: preprocessed, parentMap })) {
          violations.push({
            line: node.loc?.start?.line + 1 || 0,
            col: node.loc?.start?.column + 1 || 0,
            snippet: preprocessed.slice(node.range?.[0] ?? 0, (node.range?.[1] ?? 0) + 1).slice(0, 80),
          });
        }
      } catch (e) {
        violations.push({ line: 0, col: 0, snippet: '', error: e.message });
      }
    }
    for (const key of Object.keys(node)) {
      const value = node[key];
      if (Array.isArray(value)) {
        for (const child of value) {
          if (child && typeof child.type === 'string') walk2(child, node);
        }
      } else if (value && typeof value === 'object' && typeof value.type === 'string') {
        walk2(value, node);
      }
    }
  })(ast, null);
  return violations;
}
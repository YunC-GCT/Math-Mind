/**
 * arkts-no-is.mjs — 类型谓词 arg is T 禁用
 *
 * Official rule ID:  arkts-no-is
 * Official error code: 10605096
 *
 * AST detection: TSTypePredicate node.
 *   TSTypePredicate: { type, parameterName, typeAnnotation, asserts? }
 *   Used in: function isString(x): x is string { ... }
 */

export default {
  id: 'arkts-no-is',
  code: '10605096',
  severity: 'error',
  title: '类型谓词 arg is T 禁用',
  fixHint: '用 `instanceof` + `as` 组合',

  matches: ['TSTypePredicate'],

  check(node) {
    return node.type === 'TSTypePredicate';
  },
};
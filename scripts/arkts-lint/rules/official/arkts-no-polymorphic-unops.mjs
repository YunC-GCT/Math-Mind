/**
 * arkts-no-polymorphic-unops.mjs — 一元算符对非数值禁用 (+, -, ~, !)
 *
 * Official rule ID:  arkts-no-polymorphic-unops
 * Official error code: 10605055
 *
 * AST detection: UnaryExpression with operators that can be polymorphic (non-numeric).
 *   Banned: `+x` (could be string concat or numeric), `~x`, `delete x` (also in own rule)
 *   Allowed: `-x` (always numeric), `!x` (always boolean)
 *
 * For PoC: flag `+x` and `~x` only (most common cases).
 *   Note: `delete` has its own rule `arkts-no-delete`.
 */

export default {
  id: 'arkts-no-polymorphic-unops',
  code: '10605055',
  severity: 'error',
  title: '一元算符 + / ~ 对非数值禁用',
  fixHint: '用 Number(x) 或显式类型转换',

  matches: ['UnaryExpression'],

  check(node) {
    return node.operator === '+' || node.operator === '~';
  },
};
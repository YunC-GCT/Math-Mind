/**
 * arkts-no-conditional-types.mjs — 条件类型 禁用 (T extends U ? X : Y)
 *
 * Official rule ID:  arkts-no-conditional-types
 * Official error code: 10605022
 *
 * AST detection: TSConditionalType node.
 *   Used in: type X = T extends U ? X : Y
 */

export default {
  id: 'arkts-no-conditional-types',
  code: '10605022',
  severity: 'error',
  title: '条件类型 禁用 (T extends U ? X : Y)',
  fixHint: '用重载或分支',

  matches: ['TSConditionalType'],

  check(node) {
    return node.type === 'TSConditionalType';
  },
};
/**
 * arkts-no-type-query.mjs — typeof x 作为类型 禁用
 *
 * Official rule ID:  arkts-no-type-query
 * Official error code: 10605060
 *
 * AST detection: TSTypeQuery node.
 *   Used in: type X = typeof someVar
 */

export default {
  id: 'arkts-no-type-query',
  code: '10605060',
  severity: 'error',
  title: 'typeof x 作为类型 禁用',
  fixHint: '用具体类型替代 typeof',

  matches: ['TSTypeQuery'],

  check(node) {
    return node.type === 'TSTypeQuery';
  },
};
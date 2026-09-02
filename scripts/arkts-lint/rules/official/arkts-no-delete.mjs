/**
 * arkts-no-delete.mjs — delete obj.prop 禁用
 *
 * Official rule ID:  arkts-no-delete
 * Official error code: 10605059
 *
 * AST detection: UnaryExpression with operator 'delete' on a MemberExpression.
 *   UnaryExpression: { operator, argument }
 */

export default {
  id: 'arkts-no-delete',
  code: '10605059',
  severity: 'error',
  title: 'delete obj.prop 禁用',
  fixHint: '设 undefined 或从对象中过滤',

  matches: ['UnaryExpression'],

  check(node) {
    if (node.operator !== 'delete') return false;
    // delete x (where x is just an Identifier) is also banned by spirit of the rule
    // but technically `delete x` only fails in strict mode. We flag any delete.
    return true;
  },
};
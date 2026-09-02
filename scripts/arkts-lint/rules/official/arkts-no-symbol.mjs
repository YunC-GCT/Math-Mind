/**
 * arkts-no-symbol.mjs — Symbol() 禁用
 *
 * Official rule ID:  arkts-no-symbol
 * Official error code: 10605002
 *
 * AST detection: Identifier with name 'Symbol' in expression position.
 * To avoid false positives, only flag when:
 *   - It's the callee of a CallExpression: Symbol(...)
 *   - It's a `new Symbol(...)` (also flagged)
 */

export default {
  id: 'arkts-no-symbol',
  code: '10605002',
  severity: 'error',
  title: 'Symbol() 禁用',
  fixHint: '用 enum 或静态常量',

  matches: ['Identifier'],

  check(node, parent) {
    if (node.name !== 'Symbol') return false;
    // Check parent context: should be the callee of a CallExpression
    // or the callee of a NewExpression
    if (parent?.type === 'CallExpression' && parent.callee === node) return true;
    if (parent?.type === 'NewExpression' && parent.callee === node) return true;
    // Also flag as member: obj.Symbol, but not obj['Symbol']
    if (parent?.type === 'MemberExpression' && parent.property === node && !parent.computed) return true;
    return false;
  },
};
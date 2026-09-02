/**
 * arkts-no-destruct-assignment.mjs — [a, b] = arr 解构赋值禁用
 *
 * Official rule ID:  arkts-no-destruct-assignment
 * Official error code: 10605069
 *
 * AST detection: AssignmentExpression with .left being an ArrayPattern or ObjectPattern.
 */

export default {
  id: 'arkts-no-destruct-assignment',
  code: '10605069',
  severity: 'error',
  title: '[a, b] = arr 解构赋值禁用',
  fixHint: '用索引访问 const a = arr[0]; const b = arr[1]',

  matches: ['AssignmentExpression'],

  check(node) {
    return (
      node.type === 'AssignmentExpression' &&
      (node.left?.type === 'ArrayPattern' || node.left?.type === 'ObjectPattern')
    );
  },
};
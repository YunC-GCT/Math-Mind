/**
 * arkts-no-class-literals.mjs — class 表达式禁用
 *
 * Official rule ID:  arkts-no-class-literals
 * Official error code: 10605050
 *
 * AST detection: ClassExpression node.
 *   ClassDeclaration is allowed.
 *   ClassExpression (e.g., `const X = class { }`) is banned.
 */

export default {
  id: 'arkts-no-class-literals',
  code: '10605050',
  severity: 'error',
  title: 'class 表达式禁用',
  fixHint: '用 class 声明,不用 class 表达式',

  matches: ['ClassExpression'],

  check(node) {
    return node.type === 'ClassExpression';
  },
};
/**
 * arkts-no-destruct-decls.mjs — let { a, b } = obj 解构声明禁用
 *
 * Official rule ID:  arkts-no-destruct-decls
 * Official error code: 10605074
 *
 * AST detection: VariableDeclarator with .id being an ArrayPattern or ObjectPattern.
 *   VariableDeclaration { kind, declarations: [VariableDeclarator] }
 *   VariableDeclarator { id: Pattern | Identifier, init }
 */

export default {
  id: 'arkts-no-destruct-decls',
  code: '10605074',
  severity: 'error',
  title: 'let { a, b } = obj 解构声明禁用',
  fixHint: 'const a = obj.a; const b = obj.b',

  matches: ['VariableDeclarator'],

  check(node) {
    if (node.type !== 'VariableDeclarator') return false;
    return node.id?.type === 'ArrayPattern' || node.id?.type === 'ObjectPattern';
  },
};
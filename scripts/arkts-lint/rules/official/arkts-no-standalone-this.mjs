/**
 * arkts-no-standalone-this.mjs — 自由函数/static 中 this 禁用
 *
 * Official rule ID:  arkts-no-standalone-this
 * Official error code: 10605093
 *
 * AST detection: ThisExpression inside a function that is not a method.
 *   Walking the AST to determine "is this inside a method" is complex.
 *   For PoC: we flag any ThisExpression not directly inside a MethodDefinition.
 *   Strict version would walk ancestors to check.
 */

export default {
  id: 'arkts-no-standalone-this',
  code: '10605093',
  severity: 'warn',  // partial detection (PoC)
  title: '自由函数/static 中 this 禁用 (partial detection)',
  fixHint: '用具体类名替代 this',

  matches: ['ThisExpression'],

  check(node, parent) {
    // If parent is a method definition, this is allowed
    if (parent?.type === 'MethodDefinition') return false;
    // If parent is a class property/method declaration, allowed
    if (parent?.type === 'PropertyDefinition' || parent?.type === 'MethodDefinition') return false;
    // If parent is a call (e.g., this.foo()), allowed
    if (parent?.type === 'CallExpression' || parent?.type === 'MemberExpression') return false;
    // Otherwise, this is in a free function/static context — flag
    return true;
  },
};
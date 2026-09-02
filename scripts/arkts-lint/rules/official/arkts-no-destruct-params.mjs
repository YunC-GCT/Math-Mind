/**
 * arkts-no-destruct-params.mjs — function f({a, b}) 解构参数禁用
 *
 * Official rule ID:  arkts-no-destruct-params
 * Official error code: 10605091
 *
 * AST detection: Function/Method params with ArrayPattern or ObjectPattern type.
 *   For functions, params are in the .params array of FunctionDeclaration/Expression/MethodDefinition.
 *   We need to check if any param is a destructuring pattern.
 */

export default {
  id: 'arkts-no-destruct-params',
  code: '10605091',
  severity: 'error',
  title: 'function f({a, b}) 解构参数禁用',
  fixHint: '显式命名参数: function f(req: { a: T; b: U }) { ... }',

  matches: ['FunctionDeclaration', 'FunctionExpression', 'MethodDefinition', 'ArrowFunctionExpression'],

  check(node) {
    if (!Array.isArray(node.params)) return false;
    return node.params.some(
      // RestElement (`...args`) is allowed (just collects args)
      (p) => (p.type === 'ArrayPattern' || p.type === 'ObjectPattern') && p.type !== 'RestElement'
    );
  },
};
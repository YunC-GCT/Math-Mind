/**
 * arkts-no-func-expressions.mjs — function 表达式禁用
 *
 * Official rule ID:  arkts-no-func-expressions
 * Official error code: 10605046
 *
 * AST detection: FunctionExpression node.
 *   FunctionDeclaration is allowed (regular function declaration).
 *   FunctionExpression (e.g., `const f = function() {}`) is banned.
 *   ArrowFunctionExpression is allowed.
 *
 * Important: MethodDefinition's .value is a FunctionExpression (the method body).
 *   That's a regular method definition, not an anonymous function expression.
 *   We need to skip MethodDefinition.value to avoid false positives.
 */

export default {
  id: 'arkts-no-func-expressions',
  code: '10605046',
  severity: 'error',
  title: 'function 表达式禁用',
  fixHint: '用箭头函数 `() => {}`',

  matches: ['FunctionExpression'],

  check(node, parent) {
    // Skip if this FunctionExpression is the body of a method definition
    // (e.g., `class X { foo() {} }` — `foo() {}` is a FunctionExpression)
    if (parent?.type === 'MethodDefinition' && parent.value === node) return false;
    // Skip if this is a Property .value (e.g., `obj.foo = function() {}` — wait, that's an
    // assignment, not a property. The case we want to flag is the RHS of an assignment.)
    // We DO want to flag FunctionExpression in AssignmentExpression, VariableDeclarator.
    return true;
  },
};
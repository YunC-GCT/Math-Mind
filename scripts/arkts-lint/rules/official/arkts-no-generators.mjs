/**
 * arkts-no-generators.mjs — function* 生成器禁用
 *
 * Official rule ID:  arkts-no-generators
 * Official error code: 10605094
 *
 * AST detection: FunctionDeclaration / FunctionExpression with generator: true.
 */

export default {
  id: 'arkts-no-generators',
  code: '10605094',
  severity: 'error',
  title: 'function* 生成器禁用',
  fixHint: '用 async/await + Promise',

  matches: ['FunctionDeclaration', 'FunctionExpression'],

  check(node) {
    return node.generator === true;
  },
};
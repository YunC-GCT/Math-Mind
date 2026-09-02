/**
 * arkts-no-call-signatures.mjs — 对象类型含 call signature 禁用
 *
 * Official rule ID:  arkts-no-call-signatures
 * Official error code: 10605014
 *
 * AST detection: TSCallSignatureDeclaration node.
 *   Used in: type X = { (x: number): string }  // call signature in type
 */

export default {
  id: 'arkts-no-call-signatures',
  code: '10605014',
  severity: 'error',
  title: '对象类型含 call signature 禁用',
  fixHint: '用箭头函数类型 (x: number) => string',

  matches: ['TSCallSignatureDeclaration'],

  check(node) {
    return node.type === 'TSCallSignatureDeclaration';
  },
};
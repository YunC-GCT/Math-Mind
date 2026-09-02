/**
 * arkts-no-private-identifiers.mjs — #field 语法禁用, 用 private 关键字
 *
 * Official rule ID:  arkts-no-private-identifiers
 * Official error code: 10605003
 *
 * AST detection: #field in class body is parsed as PropertyDefinition with
 *   key.type === 'PrivateIdentifier'. (The TSPrivateIdentifier AST node type
 *   only appears for type references like `this.#x`.)
 */

export default {
  id: 'arkts-no-private-identifiers',
  code: '10605003',
  severity: 'error',
  title: '#field 语法禁用, 用 private 关键字',
  fixHint: '用 private (TS 风格) 替代 #field',

  matches: ['PropertyDefinition'],

  check(node) {
    return node.key?.type === 'PrivateIdentifier';
  },
};
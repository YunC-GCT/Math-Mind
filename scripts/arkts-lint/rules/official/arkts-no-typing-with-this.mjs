/**
 * arkts-no-typing-with-this.mjs — this 类型禁用
 *
 * Official rule ID:  arkts-no-typing-with-this
 * Official error code: 10605021
 *
 * AST detection: TSThisType node.
 *   Used in: type X = this; function foo(x: this) { ... }
 */

export default {
  id: 'arkts-no-typing-with-this',
  code: '10605021',
  severity: 'error',
  title: 'this 类型禁用',
  fixHint: '用具体类名替代 this',

  matches: ['TSThisType'],

  check(node) {
    return node.type === 'TSThisType';
  },
};
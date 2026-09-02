/**
 * arkts-no-for-in.mjs — for..in 循环禁用
 *
 * Official rule ID:  arkts-no-for-in
 * Official error code: 10605080
 * Source: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-migration-background
 * Quote: "ArkTS不支持for .. in迭代对象属性。"
 *
 * AST detection: ForInStatement node.
 *   ForInStatement: { type, left: VariableDeclaration | Pattern, right: Expression, body }
 * Note: for..of is allowed (different node: ForOfStatement).
 */

export default {
  id: 'arkts-no-for-in',
  code: '10605080',
  severity: 'error',
  title: 'for..in 循环禁用',
  fixHint: '用 for...of 或 forEach',

  matches: ['ForInStatement'],

  check(node) {
    return node.type === 'ForInStatement';
  },
};
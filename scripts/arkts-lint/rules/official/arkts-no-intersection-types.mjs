/**
 * arkts-no-intersection-types.mjs — 类型位置上的 T & U 交叉类型禁用
 *
 * Official rule ID:  arkts-no-intersection-types
 * Official error code: 10605019
 *
 * AST detection: TSIntersectionType node.
 *   Used in: type A = B & C
 */

export default {
  id: 'arkts-no-intersection-types',
  code: '10605019',
  severity: 'error',
  title: 'T & U 交叉类型禁用',
  fixHint: '用 interface extends A, B 替代',

  matches: ['TSIntersectionType'],

  check(node) {
    return node.type === 'TSIntersectionType';
  },
};
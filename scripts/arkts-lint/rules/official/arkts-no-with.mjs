/**
 * arkts-no-with.mjs — with 语句禁用
 *
 * Official rule ID:  arkts-no-with
 * Official error code: 10605084
 *
 * AST detection: WithStatement node.
 *   WithStatement: { type, object, body }
 */

export default {
  id: 'arkts-no-with',
  code: '10605084',
  severity: 'error',
  title: 'with 语句禁用',
  fixHint: '用显式属性访问替代',

  matches: ['WithStatement'],

  check(node) {
    return node.type === 'WithStatement';
  },
};
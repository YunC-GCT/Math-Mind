/**
 * arkts-no-indexed-signatures.mjs — [k: T]: V 索引签名 禁用
 *
 * Official rule ID:  arkts-no-indexed-signatures
 * Official error code: 10605017
 *
 * AST detection: TSIndexSignature node.
 *   Used in: interface X { [key: string]: number }
 */

export default {
  id: 'arkts-no-indexed-signatures',
  code: '10605017',
  severity: 'error',
  title: '[k: T]: V 索引签名 禁用',
  fixHint: '用 Map<K, V>',

  matches: ['TSIndexSignature'],

  check(node) {
    return node.type === 'TSIndexSignature';
  },
};
/**
 * arkts-no-ctor-prop-decls.mjs — 构造函数参数中声明字段 禁用
 *
 * Official rule ID:  arkts-no-ctor-prop-decls
 * Official error code: 10605025
 *
 * AST detection: TSParameterProperty node.
 *   Used in: class X { constructor(public name: string) {} }
 *   Should be: class X { name: string; constructor(name: string) { this.name = name } }
 */

export default {
  id: 'arkts-no-ctor-prop-decls',
  code: '10605025',
  severity: 'error',
  title: '构造函数参数中声明字段 禁用',
  fixHint: '显式声明字段 + 构造函数赋值',

  matches: ['TSParameterProperty'],

  check(node) {
    return node.type === 'TSParameterProperty';
  },
};
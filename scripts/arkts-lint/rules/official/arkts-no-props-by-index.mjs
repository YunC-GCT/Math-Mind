/**
 * arkts-no-props-by-index.mjs — obj['key'] 动态属性访问禁用
 *
 * Official rule ID:  arkts-no-props-by-index
 * Official error code: 10605029
 *
 * AST detection: MemberExpression with .computed=true and .property being a string literal.
 *   Allowed: obj.foo, obj[someVar]
 *   Not allowed: obj['foo']
 */

export default {
  id: 'arkts-no-props-by-index',
  code: '10605029',
  severity: 'warn',
  title: 'obj["key"] 动态属性访问禁用 (JSON 解析场景不可避免, 标 warn)',

  matches: ['MemberExpression'],
  fixHint: '预定义字段 或 Map.get()',

  check(node) {
    if (!node.computed) return false;
    // property is a string literal
    return node.property?.type === 'Literal' && typeof node.property.value === 'string';
  },
};
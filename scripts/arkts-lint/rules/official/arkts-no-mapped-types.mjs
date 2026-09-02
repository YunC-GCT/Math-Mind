/**
 * arkts-no-mapped-types.mjs — mapped types 禁用 ([K in keyof T])
 *
 * Official rule ID:  arkts-no-mapped-types
 * Official error code: 10605083
 *
 * AST detection: TSMappedType node.
 *   TSMappedType: { type, typeParameter: TSTypeParameter, typeAnnotation, nameType? }
 */

export default {
  id: 'arkts-no-mapped-types',
  code: '10605083',
  severity: 'error',
  title: 'mapped types 禁用 ([K in keyof T])',
  fixHint: '显式字段声明',

  matches: ['TSMappedType'],

  check(node) {
    return node.type === 'TSMappedType';
  },
};
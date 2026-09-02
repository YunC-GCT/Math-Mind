/**
 * arkts-no-structural-typing.mjs — 结构兼容禁用
 *
 * Official rule ID:  arkts-no-structural-typing
 * Official error code: 10605030
 *
 * AST detection: TSPropertySignature / TSIndexSignature in TSTypeLiteral
 *   (without explicit type annotation on the property).
 *   Structural typing: { a: string } assigned to { a: any } without explicit
 *   declaration. Detected via type literals without type annotation.
 *
 * For PoC: flag TSTypeLiteral where any TSPropertySignature lacks a
 *   typeAnnotation.
 *
 * Note: this is a partial detection. Full detection requires type checker.
 */

export default {
  id: 'arkts-no-structural-typing',
  code: '10605030',
  severity: 'warn',  // partial detection
  title: '结构兼容禁用 (partial detection)',
  fixHint: '显式声明字段类型',

  matches: ['TSTypeLiteral'],

  check(node) {
    if (!Array.isArray(node.members)) return false;
    // Flag if any member is a property/index signature without type annotation
    return node.members.some(
      (m) =>
        (m.type === 'TSPropertySignature' || m.type === 'TSIndexSignature') &&
        !m.typeAnnotation
    );
  },
};
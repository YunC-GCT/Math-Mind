/**
 * arkts-implements-only-iface.mjs — implements 必须是 interface, 不能是 class
 *
 * Official rule ID:  arkts-implements-only-iface
 * Official error code: 10605051
 *
 * AST detection: ClassDeclaration / ClassExpression with .implementsNames.
 *   The implementsNames are TSExpressionWithTypeArguments nodes.
 *   Each has .expression which is the type name (Identifier or MemberExpression).
 *   We can't easily distinguish interface from class by AST alone (TS-ESTree doesn't
 *   track declaration kind on references), so we warn: a heuristic — if the implements
 *   name starts with `I` (interface convention) or is in a known interface list, allow.
 *   Otherwise flag as warning for manual review.
 *
 * For PoC: we just flag ALL implements clauses as warnings, since this is a
 * "review" check, not a compile-blocking error.
 */

export default {
  id: 'arkts-implements-only-iface',
  code: '10605051',
  severity: 'warn',
  title: 'implements 必须是 interface (AST 难区分, 需人工核对)',

  matches: ['ClassDeclaration', 'ClassExpression'],
  fixHint: '确认 implements 的是 interface (命名约定 I 前缀或单独定义)',

  check(node) {
    if (!Array.isArray(node.implements) || node.implements.length === 0) return false;
    // Flag every class with implements — user should verify they're interfaces
    return true;
  },
};
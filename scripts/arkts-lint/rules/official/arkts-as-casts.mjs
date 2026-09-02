/**
 * arkts-as-casts.mjs — 尖括号强转 <T>x 禁用, 用 x as T
 *
 * Official rule ID:  arkts-as-casts
 * Official error code: 10605053
 *
 * AST detection: TSAsExpression (allowed) vs <T>x (not parsed by TS-ESTree).
 *   Since TS-ESTree only emits TSAsExpression for `x as T` syntax, the only
 *   way `<T>x` could appear in the AST is through preprocessor leaks. In
 *   practice, this rule is hard to detect via AST alone. We use a fallback
 *   approach: scan the preprocessed source for `<T>x` patterns not in JSX context.
 *   For PoC, this rule is implemented as a secondary text scan (not pure AST).
 *
 * Note: In TS-ESTree, `<T>` in a position like `f<T>(x)` is parsed as TSTypeParameterInstantiation,
 *   which is different from a cast. True `<T>x` cast syntax in TypeScript source is
 *   rare; it's a legacy form. Most code uses `x as T`.
 *
 * For this rule, we use a combined approach:
 *   1. AST: look for TSTypeAssertion node (which is the AST for `<T>x` cast)
 *   2. If not present in this version, skip (no-op)
 */

export default {
  id: 'arkts-as-casts',
  code: '10605053',
  severity: 'error',
  title: '尖括号强转 <T>x 禁用, 用 x as T',
  fixHint: '改为 `(x as Foo)` 形式',

  matches: ['TSTypeAssertion'],

  check(node) {
    // TSTypeAssertion is the AST node for `<T>x` syntax
    return node.type === 'TSTypeAssertion';
  },
};
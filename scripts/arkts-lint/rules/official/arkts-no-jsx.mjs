/**
 * arkts-no-jsx.mjs — JSX 禁用 (ArkTS 不支持 JSX)
 *
 * Official rule ID:  arkts-no-jsx
 * Official error code: 10605054
 *
 * AST detection: JSXElement / JSXFragment / JSXText nodes.
 *   In ArkTS, build() method bodies use ArkUI-specific syntax (Component() { ... }),
 *   not JSX (<Component />). With parser in `jsx: true` mode for ArkUI compat,
 *   the parser emits JSXElement / JSXFragment nodes — these are bugs to flag.
 */

export default {
  id: 'arkts-no-jsx',
  code: '10605054',
  severity: 'error',
  title: 'JSX 禁用 (ArkTS 用 @Builder 而非 <Component />)',
  fixHint: '用 @Builder 方法或 ArkUI 组件调用',

  matches: ['JSXElement', 'JSXFragment'],

  check(node) {
    return node.type === 'JSXElement' || node.type === 'JSXFragment';
  },
};
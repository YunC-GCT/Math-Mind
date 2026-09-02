/**
 * no-get-accessor.mjs — struct 内禁 get accessor (项目偏好)
 *
 * Project preference: project-pref
 *
 * AST detection: MethodDefinition with kind === 'get'.
 *   Allowed: regular method (kind: 'method'), arrow function field (PropertyDefinition)
 *   Not allowed: get accessor (kind: 'get')
 */

import { hasDecorator } from '../../ast-utils/has-decorator.mjs';

export default {
  id: 'no-get-accessor',
  code: 'project-pref',
  severity: 'warn',
  title: 'struct 内禁 get accessor (项目偏好)',

  matches: ['MethodDefinition'],
  fixHint: '用 @State 直接暴露或 @Computed (API 12+)',

  check(node, parent, ctx) {
    if (node.kind !== 'get') return false;
    const classNode = ctx?.parentMap?.get?.(parent);
    if (!classNode) return false;
    return hasDecorator(classNode, ['Component', 'Observed', 'ComponentV2', 'ObservedV2']);
  },
};
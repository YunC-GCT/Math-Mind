/**
 * struct-no-regular-methods.mjs — ArkUI struct 内禁普通方法 (项目偏好)
 *
 * Project preference: arkts-no-struct-methods (project-pref)
 *
 * In ArkUI, @Component struct methods should use arrow function fields, not
 * regular method declarations. This rule is a project preference (NOT a
 * strict-mode violation) and is enforced only on structs decorated with
 * @Component (NOT on plain class).
 *
 * AST detection: MethodDefinition inside ClassDeclaration with @Component decorator,
 *   where the method's .value is a FunctionExpression (regular method),
 *   NOT an arrow function (ArrowFunctionExpression has no FunctionExpression wrapper).
 *
 *   MethodDefinition: { type, key, value: FunctionExpression, kind: 'method' | 'constructor' | ... }
 *   Arrow function fields are stored as PropertyDefinition with value: ArrowFunctionExpression,
 *   NOT as MethodDefinition.
 *
 *   So: a MethodDefinition inside a @Component-decorated class IS a regular method.
 */

import { hasDecorator } from '../../ast-utils/has-decorator.mjs';
import { findAll } from '../../ast-utils/walk.mjs';

export default {
  id: 'struct-no-regular-methods',
  code: 'project-pref',
  severity: 'warn',
  title: 'struct 内禁用普通方法 (项目偏好, 官方允许)',

  matches: ['MethodDefinition'],
  fixHint: '用箭头函数字段 `handleClick = (): void => { ... }`',

  /**
   * Check requires parent context (ClassDeclaration with @Component).
   * For PoC, we accept that this is a slight over-flag: a MethodDefinition inside
   * ANY class is flagged. A proper implementation would walk up to the enclosing
   * ClassDeclaration and check for @Component.
   *
   * @param {object} node MethodDefinition
   * @param {object} parent ClassBody (direct parent)
   */
  check(node, parent, ctx) {
    // Skip constructor (kind: 'constructor') — constructors are always regular
    if (node.kind === 'constructor') return false;
    // Skip static methods (static: true) — also always regular
    if (node.static === true) return false;
    // AST nodes don't have built-in .parent; use the parentMap from ctx.
    // The parent of MethodDefinition is ClassBody, whose parent is the class.
    const classBody = parent;
    const classNode = ctx?.parentMap?.get?.(classBody);
    if (!classNode) return false;
    // Only flag if the enclosing class is a struct (has @Component or @Observed)
    return hasDecorator(classNode, ['Component', 'Observed', 'ComponentV2', 'ObservedV2']);
  },
};
/**
 * ast-utils/has-decorator.mjs — check if a node has a given decorator
 *
 * In ArkUI, structs are decorated with @Component, @Observed, etc.
 * Distinguishing them from plain class declarations is essential for ArkUI project rules.
 */

/**
 * @param {object} node  AST node (must be a ClassDeclaration / ClassExpression / similar)
 * @param {string|string[]} decoratorNames  decorator name(s) to look for
 * @returns {boolean}
 */
export function hasDecorator(node, decoratorNames) {
  if (!node) return false;
  const decorators = node.decorators;
  if (!Array.isArray(decorators) || decorators.length === 0) return false;
  const names = Array.isArray(decoratorNames) ? decoratorNames : [decoratorNames];
  for (const dec of decorators) {
    // Decorator: { expression: Identifier | CallExpression }
    const expr = dec.expression;
    if (!expr) continue;
    let name = null;
    if (expr.type === 'Identifier') {
      name = expr.name;
    } else if (expr.type === 'CallExpression' && expr.callee?.type === 'Identifier') {
      name = expr.callee.name;
    }
    if (name && names.includes(name)) return true;
  }
  return false;
}

/**
 * Is this a struct decorated for ArkUI components?
 * (Loose match: any @Component* / @Observed* family)
 */
export function isArkUIStructLike(node) {
  if (!node) return false;
  const ARCH_DECORATORS = [
    'Component',
    'ComponentV2',
    'Observed',
    'ObservedV2',
    'ReusableComponent',
    'CustomDialog',
  ];
  return hasDecorator(node, ARCH_DECORATORS);
}

/**
 * Is this an @Entry-annotated file-level entry point?
 */
export function isEntryAbility(node) {
  return hasDecorator(node, ['Entry']);
}
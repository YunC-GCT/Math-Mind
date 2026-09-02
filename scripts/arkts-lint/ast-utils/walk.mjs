/**
 * ast-utils/walk.mjs — Generic AST walker
 *
 * Calls visitor.enter(node, parent) on entry, visitor.leave(node, parent) on exit.
 * VisitorChildren can return false to skip subtree.
 */

/**
 * ast-utils/walk.mjs — Generic AST walker
 *
 * Calls visitor.enter(node, parent) on entry, visitor.leave(node, parent) on exit.
 * VisitorChildren can return false to skip subtree.
 */

/**
 * @param {object} root  AST node to walk
 * @param {{
 *   enter?: (node: object, parent: object | null) => boolean | void,
 *   leave?: (node: object, parent: object | null) => void,
 * }} visitor
 */
export function walk(root, visitor) {
  function visit(node, parent) {
    if (!node || typeof node !== 'object') return;
    let skipChildren = false;
    if (visitor.enter) {
      const result = visitor.enter(node, parent);
      if (result === false) skipChildren = true;
    }
    if (!skipChildren) {
      for (const key of Object.keys(node)) {
        if (key === 'parent') continue;
        const value = node[key];
        if (Array.isArray(value)) {
          for (const child of value) {
            if (child && typeof child.type === 'string') {
              visit(child, node);
            }
          }
        } else if (value && typeof value === 'object' && typeof value.type === 'string') {
          visit(value, node);
        }
      }
    }
    if (visitor.leave) visitor.leave(node, parent);
  }
  visit(root, null);
}

/**
 * Convenience: find all nodes matching a predicate (DFS, pre-order).
 * @param {object} root
 * @param {(node: object) => boolean} predicate
 * @returns {object[]}
 */
export function findAll(root, predicate) {
  const result = [];
  walk(root, {
    enter(node) {
      if (predicate(node)) result.push(node);
    },
  });
  return result;
}
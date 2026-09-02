/**
 * arkts-no-nested-funcs.mjs — 嵌套函数声明禁用
 *
 * Official rule ID:  arkts-no-nested-funcs
 * Official error code: 10605092
 *
 * AST detection: FunctionDeclaration whose parent is a BlockStatement that's
 * inside another function (FunctionDeclaration/Expression/Method).
 *   For PoC: simple check — direct parent is BlockStatement, and BlockStatement's
 *   parent is a function-like node.
 *   Note: full check requires walking the entire ancestor chain.
 */

import { findAll } from '../../ast-utils/walk.mjs';

export default {
  id: 'arkts-no-nested-funcs',
  code: '10605092',
  severity: 'error',
  title: '嵌套函数声明禁用',
  fixHint: '提取为模块顶层函数或箭头',

  matches: ['FunctionDeclaration'],

  check(node, parent, ctx) {
    if (!parent) return false;
    // Top-level function declaration's parent is Program.
    // Nested function's parent is BlockStatement (which is inside another function).
    if (parent.type === 'BlockStatement') {
      // Check if the BlockStatement's parent is a function-like node
      const grandParent = ctx?.parentMap?.get?.(parent);
      if (grandParent && (grandParent.type === 'FunctionDeclaration' ||
          grandParent.type === 'FunctionExpression' ||
          grandParent.type === 'ArrowFunctionExpression' ||
          grandParent.type === 'MethodDefinition')) {
        return true;
      }
    }
    return false;
  },
};
/**
 * arkts-no-var.mjs — var 声明禁用, 用 let
 *
 * Official rule ID:  arkts-no-var
 * Official error code: 10605005
 *
 * AST detection: VariableDeclaration with kind 'var'.
 *   VariableDeclaration: { kind: 'var' | 'let' | 'const', declarations }
 */

export default {
  id: 'arkts-no-var',
  code: '10605005',
  severity: 'error',
  title: 'var 禁用, 用 let',
  fixHint: 'var 改 let',

  matches: ['VariableDeclaration'],

  check(node) {
    return node.kind === 'var';
  },
};
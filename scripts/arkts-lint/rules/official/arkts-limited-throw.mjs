/**
 * arkts-limited-throw.mjs — throw 非 Error 禁用 (throw "string" 等)
 *
 * Official rule ID:  arkts-limited-throw
 * Official error code: 10605087
 *
 * AST detection: ThrowStatement whose .argument is NOT a NewExpression.
 *   ThrowStatement: { type, argument }
 *   Allowed: throw new Error('msg'), throw new SomeCustomError()
 *   Not allowed: throw 'msg', throw someVar, throw null, throw undefined
 */

export default {
  id: 'arkts-limited-throw',
  code: '10605087',
  severity: 'error',
  title: 'throw 非 Error 禁用 (throw "string" 等)',
  fixHint: 'throw new Error("...")',

  matches: ['ThrowStatement'],

  check(node) {
    return node.argument?.type !== 'NewExpression';
  },
};
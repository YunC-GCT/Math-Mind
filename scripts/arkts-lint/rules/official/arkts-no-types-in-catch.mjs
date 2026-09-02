/**
 * arkts-no-types-in-catch.mjs — catch (e: T) typed 禁用
 *
 * Official rule ID:  arkts-no-types-in-catch
 * Official error code: 10605079
 *
 * AST detection: CatchClause with param.typeAnnotation.
 *   CatchClause: { type, param: Pattern | null, body }
 *   In TypeScript ESTree, typed catch param has .param.typeAnnotation.
 */

export default {
  id: 'arkts-no-types-in-catch',
  code: '10605079',
  severity: 'error',
  title: 'catch (e: T) typed 禁用',
  fixHint: 'catch (e) + (e as Error).message ?? String(e)',

  matches: ['CatchClause'],

  check(node) {
    if (!node.param) return false;
    // In TS-ESTree, a typed catch param has typeAnnotation on the param's Identifier
    return node.param.typeAnnotation !== undefined && node.param.typeAnnotation !== null;
  },
};
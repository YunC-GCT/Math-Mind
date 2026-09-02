/**
 * arkts-no-any-unknown.mjs — any / unknown 类型禁用 (PoC rule)
 *
 * Official rule ID:  arkts-no-any-unknown
 * Official error code: 10605008
 * Source: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-migration-background
 * Quote: "ArkTS不支持any和unknown类型。显式指定具体类型。"
 *
 * PoC: This is the first rule migrated from v1 regex → v2 AST.
 * Demonstrates that AST parsing correctly distinguishes type positions
 * from string literals / comments / identifiers.
 */

export default {
  id: 'arkts-no-any-unknown',
  code: '10605008',
  severity: 'error',
  title: 'any / unknown 类型禁用',
  fixHint: '用具体类型; catch 处 (e as Error).message ?? String(e)',

  matches: ['TSAnyKeyword', 'TSUnknownKeyword'],

  /**
   * Detect any / unknown at a type position.
   *
   * The parser emits TSAnyKeyword / TSUnknownKeyword ONLY when they appear
   * as actual type annotations (function params, variable types, class fields, etc.).
   * String literals like "any" are Token types, not keywords.
   * Variable identifiers like anything are Identifiers, not keywords.
   *
   * Therefore, simple type-only check is sufficient.
   */
  check(node) {
    return node.type === 'TSAnyKeyword' || node.type === 'TSUnknownKeyword';
  },
};
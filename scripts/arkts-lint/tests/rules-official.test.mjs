/**
 * rules-official.test.mjs — unit tests for all official rules
 *
 * Uses Node's built-in test runner (node:test).
 * Each rule is tested with a small inline source that should (or should not) trigger it.
 *
 * Run with: node --test tests/rules-official.test.mjs
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';

// Test runner
import { runRuleOnSource } from './run-rule.mjs';

// Rule imports
import anyUnknown from '../rules/official/arkts-no-any-unknown.mjs';
import forIn from '../rules/official/arkts-no-for-in.mjs';
import withRule from '../rules/official/arkts-no-with.mjs';
import del from '../rules/official/arkts-no-delete.mjs';
import varRule from '../rules/official/arkts-no-var.mjs';
import privateId from '../rules/official/arkts-no-private-identifiers.mjs';
import symbol from '../rules/official/arkts-no-symbol.mjs';
import typesInCatch from '../rules/official/arkts-no-types-in-catch.mjs';
import asCasts from '../rules/official/arkts-as-casts.mjs';
import classLit from '../rules/official/arkts-no-class-literals.mjs';
import funcExpr from '../rules/official/arkts-no-func-expressions.mjs';
import jsx from '../rules/official/arkts-no-jsx.mjs';
import generator from '../rules/official/arkts-no-generators.mjs';
import nestedFuncs from '../rules/official/arkts-no-nested-funcs.mjs';
import destructAssign from '../rules/official/arkts-no-destruct-assignment.mjs';
import destructDecls from '../rules/official/arkts-no-destruct-decls.mjs';
import destructParams from '../rules/official/arkts-no-destruct-params.mjs';
import isRule from '../rules/official/arkts-no-is.mjs';
import intersection from '../rules/official/arkts-no-intersection-types.mjs';
import mapped from '../rules/official/arkts-no-mapped-types.mjs';
import limitedThrow from '../rules/official/arkts-limited-throw.mjs';
import propsByIndex from '../rules/official/arkts-no-props-by-index.mjs';
import implementsOnlyIface from '../rules/official/arkts-implements-only-iface.mjs';
import structuralTyping from '../rules/official/arkts-no-structural-typing.mjs';
import typingWithThis from '../rules/official/arkts-no-typing-with-this.mjs';
import typeQuery from '../rules/official/arkts-no-type-query.mjs';
import callSigs from '../rules/official/arkts-no-call-signatures.mjs';
import ctorPropDecls from '../rules/official/arkts-no-ctor-prop-decls.mjs';
import indexedSigs from '../rules/official/arkts-no-indexed-signatures.mjs';
import polyUnops from '../rules/official/arkts-no-polymorphic-unops.mjs';
import standaloneThis from '../rules/official/arkts-no-standalone-this.mjs';
import conditionalTypes from '../rules/official/arkts-no-conditional-types.mjs';

// Project rules
import structMethods from '../rules/project/struct-no-regular-methods.mjs';
import getAccessor from '../rules/project/no-get-accessor.mjs';

// Helper: assert exactly N violations
function expectViolations(rule, source, expectedCount, label) {
  const violations = runRuleOnSource(rule, source, label);
  assert.equal(
    violations.length,
    expectedCount,
    `${label}: expected ${expectedCount} violations, got ${violations.length}\n` +
      `  Violations: ${JSON.stringify(violations.map(v => v.line + ':' + v.snippet))}\n` +
      `  Source: ${source}`
  );
}

// ─── A. 类型系统 ───

test('arkts-no-any-unknown: catches any', () => {
  expectViolations(anyUnknown, 'function f(x: any): any { return x; }', 2, 'any-test');
});

test('arkts-no-any-unknown: catches unknown', () => {
  expectViolations(anyUnknown, 'let u: unknown;', 1, 'unknown-test');
});

test('arkts-no-any-unknown: no false positive on string', () => {
  expectViolations(anyUnknown, 'const s: string = "anyway";', 0, 'string-test');
});

test('arkts-no-typing-with-this: catches this type', () => {
  expectViolations(typingWithThis, 'function f(x: this) {}', 1, 'this-type');
});

test('arkts-no-type-query: catches typeof', () => {
  expectViolations(typeQuery, 'type X = typeof someVar;', 1, 'typeof-type');
});

test('arkts-no-intersection-types: catches A & B', () => {
  expectViolations(intersection, 'type X = A & B;', 1, 'intersection');
});

test('arkts-no-mapped-types: catches keyof T', () => {
  expectViolations(mapped, 'type X<T> = { [K in keyof T]: T[K] };', 1, 'mapped');
});

test('arkts-no-conditional-types: catches T extends U ? X : Y', () => {
  expectViolations(conditionalTypes, 'type X<T> = T extends number ? 1 : 0;', 1, 'conditional');
});

test('arkts-as-casts: catches <T>x', () => {
  expectViolations(asCasts, 'const s = <string>x;', 1, 'as-casts');
});

test('arkts-no-call-signatures: catches call sig in type', () => {
  expectViolations(callSigs, 'type X = { (n: number): string };', 1, 'call-sig');
});

test('arkts-no-indexed-signatures: catches [k: T]: V', () => {
  expectViolations(indexedSigs, 'interface X { [key: string]: number; }', 1, 'indexed-sig');
});

test('arkts-no-ctor-prop-decls: catches public in constructor', () => {
  expectViolations(ctorPropDecls, 'class X { constructor(public name: string) {} }', 1, 'ctor-prop');
});

// ─── B. 控制流 ───

test('arkts-no-for-in: catches for-in', () => {
  expectViolations(forIn, 'for (const k in obj) { console.log(k); }', 1, 'for-in');
});

test('arkts-no-for-in: no false positive on for-of', () => {
  expectViolations(forIn, 'for (const v of arr) { console.log(v); }', 0, 'for-of');
});

test('arkts-no-with: catches with', () => {
  expectViolations(withRule, 'with (obj) { foo = bar; }', 1, 'with');
});

test('arkts-no-delete: catches delete obj.prop', () => {
  expectViolations(del, 'delete obj.foo;', 1, 'delete');
});

// ─── C. 变量声明 ───

test('arkts-no-var: catches var', () => {
  expectViolations(varRule, 'var x = 1;', 1, 'var');
});

test('arkts-no-private-identifiers: catches #field', () => {
  expectViolations(privateId, 'class X { #secret: string = ""; }', 1, 'private-id');
});

test('arkts-no-symbol: catches Symbol()', () => {
  expectViolations(symbol, 'const s = Symbol("foo");', 1, 'symbol');
});

test('arkts-no-types-in-catch: catches catch (e: T)', () => {
  expectViolations(typesInCatch, 'try { foo(); } catch (e: Error) { bar(); }', 1, 'types-catch');
});

test('arkts-no-types-in-catch: allows catch (e)', () => {
  expectViolations(typesInCatch, 'try { foo(); } catch (e) { bar(); }', 0, 'types-catch-ok');
});

// ─── D. 类与对象 ───

test('arkts-no-class-literals: catches const X = class {}', () => {
  expectViolations(classLit, 'const X = class { foo() {} };', 1, 'class-literal');
});

test('arkts-no-func-expressions: catches const f = function()', () => {
  expectViolations(funcExpr, 'const f = function() {};', 1, 'func-expr');
});

test('arkts-no-func-expressions: allows arrow functions', () => {
  expectViolations(funcExpr, 'const f = () => {};', 0, 'arrow-ok');
});

test('arkts-no-jsx: catches <div />', () => {
  // 1 violation: the JSXElement node (OpeningElement and ClosingElement are children, not separate violations)
  expectViolations(jsx, 'const x = <div>hi</div>;', 1, 'jsx');
});

test('arkts-no-generators: catches function*', () => {
  expectViolations(generator, 'function* gen() { yield 1; }', 1, 'generator');
});

test('arkts-no-destruct-assignment: catches [a,b] = arr', () => {
  expectViolations(destructAssign, '[a, b] = [1, 2];', 1, 'destruct-assign');
});

test('arkts-no-destruct-decls: catches let {a,b} = obj', () => {
  expectViolations(destructDecls, 'let {a, b} = {a: 1, b: 2};', 1, 'destruct-decl');
});

test('arkts-no-destruct-params: catches function f({a,b})', () => {
  expectViolations(destructParams, 'function f({a, b}: {a: number, b: string}) { return a; }', 1, 'destruct-param');
});

test('arkts-no-destruct-params: allows rest', () => {
  expectViolations(destructParams, 'function f(...args: any[]) { return args; }', 0, 'destruct-rest-ok');
});

test('arkts-no-is: catches arg is T', () => {
  expectViolations(isRule, 'function isFoo(x: any): x is string { return typeof x === "string"; }', 1, 'is');
});

test('arkts-no-nested-funcs: catches function in function', () => {
  expectViolations(nestedFuncs, 'function outer() { function inner() {} }', 1, 'nested');
});

test('arkts-no-props-by-index: catches obj["key"]', () => {
  expectViolations(propsByIndex, 'const v = obj["key"];', 1, 'props-by-index');
});

test('arkts-implements-only-iface: warns on any implements', () => {
  expectViolations(implementsOnlyIface, 'class X implements Y {}', 1, 'implements');
});

test('arkts-limited-throw: catches throw "string"', () => {
  expectViolations(limitedThrow, 'throw "something went wrong";', 1, 'limited-throw');
});

test('arkts-limited-throw: allows throw new Error()', () => {
  expectViolations(limitedThrow, 'throw new Error("oops");', 0, 'limited-throw-ok');
});

test('arkts-no-structural-typing: catches untyped object literal type', () => {
  // Note: TS requires every property in a type literal to have a type annotation.
  // So a true "untyped" property literal isn't syntactically valid in TS.
  // The rule catches cases where the typeAnnotation is missing.
  // This test uses an indexed signature without type, which IS untyped syntactically.
  expectViolations(structuralTyping, 'type X = { [k: string] };', 1, 'structural');
});

test('arkts-no-polymorphic-unops: catches +x', () => {
  expectViolations(polyUnops, 'const n = +x;', 1, 'plus-unop');
});

test('arkts-no-polymorphic-unops: catches ~x', () => {
  expectViolations(polyUnops, 'const n = ~x;', 1, 'tilde-unop');
});

test('arkts-no-polymorphic-unops: allows -x and !x', () => {
  expectViolations(polyUnops, 'const a = -x; const b = !y;', 0, 'mono-unop');
});

test('arkts-no-standalone-this: catches this in free function', () => {
  expectViolations(standaloneThis, 'function free() { return this; }', 1, 'standalone-this');
});

// ─── E. Project rules ───

test('struct-no-regular-methods: catches @Component struct method', () => {
  expectViolations(
    structMethods,
    '@Component struct X { foo() { return 1; } }',
    1,
    'struct-method-bad'
  );
});

test('struct-no-regular-methods: allows plain class method (rule is struct-specific)', () => {
  expectViolations(structMethods, 'class X { foo() { return 1; } }', 0, 'plain-class-ok');
});

test('struct-no-regular-methods: allows @Component struct arrow method', () => {
  expectViolations(
    structMethods,
    '@Component struct X { foo = (): number => 1; }',
    0,
    'struct-arrow-ok'
  );
});

test('no-get-accessor: catches get in @Component struct', () => {
  expectViolations(
    getAccessor,
    '@Component struct X { get foo(): number { return 1; } }',
    1,
    'struct-get-bad'
  );
});

test('no-get-accessor: plain class get not flagged (project rule applies to structs only)', () => {
  expectViolations(getAccessor, 'class X { get foo(): number { return 1; } }', 0, 'plain-class-get-ok');
});

// ─── Z. Sanity: passing fixture ───

test('fixture: any-type.ets → 6 any/unknown violations', () => {
  const src = `function bad1(x: any): any { return x; }
function bad2(unknown: unknown) {}
const a: any = 42;
let u: unknown;
interface Mixed { ok: string; bad: any; }`;
  const violations = runRuleOnSource(anyUnknown, src, 'any-type-fixture');
  assert.equal(violations.length, 6, `expected 6, got ${violations.length}`);
});

test('fixture: no-any.ets → 0 any/unknown violations', () => {
  const src = `interface Foo { name: string; count: number; }
function greet(f: Foo): string { return 'hello ' + f.name; }
class Container { items: string[] = []; }
const x: number = 42;`;
  const violations = runRuleOnSource(anyUnknown, src, 'no-any-fixture');
  assert.equal(violations.length, 0, `expected 0, got ${violations.length}`);
});
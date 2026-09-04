/**
 * scripts/naming-lint/tests/rule-checkers.test.mjs
 *
 * Unit tests for the rule-checker helpers (no filesystem access).
 * Run: node --test tests/rule-checkers.test.mjs
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { isKebabCase, isPascalCase, isSnakeCase, isIsoDate } from '../rule-checkers.mjs';

test('isKebabCase accepts valid kebab', () => {
  assert.ok(isKebabCase('foo'));
  assert.ok(isKebabCase('foo-bar'));
  assert.ok(isKebabCase('foo-bar-baz'));
  assert.ok(isKebabCase('foo-1'));
  assert.ok(isKebabCase('a1b2'));
  // Versioned names: arkts-1.1, langgraph-1.0.0
  assert.ok(isKebabCase('arkts-1.1'));
  assert.ok(isKebabCase('langgraph-1.0.0'));
});

test('isKebabCase rejects invalid kebab', () => {
  assert.ok(!isKebabCase('FooBar'));
  assert.ok(!isKebabCase('foo_bar'));
  assert.ok(!isKebabCase('fooBar'));
  assert.ok(!isKebabCase('-foo'));
  assert.ok(!isKebabCase('foo-'));
  assert.ok(!isKebabCase('foo--bar'));
  assert.ok(!isKebabCase(''));
});

test('isPascalCase accepts valid', () => {
  assert.ok(isPascalCase('Button'));
  assert.ok(isPascalCase('SearchField'));
  assert.ok(isPascalCase('A1'));
  assert.ok(isPascalCase('UserCard'));
  assert.ok(isPascalCase('A'));
});

test('isPascalCase rejects invalid', () => {
  assert.ok(!isPascalCase('button'));
  assert.ok(!isPascalCase('Button-Component'));
  assert.ok(!isPascalCase('Button_component'));
  assert.ok(!isPascalCase(''));
  assert.ok(!isPascalCase('1Button'));
  // Note: 'ButtonComponent' (multi-word PascalCase) is ACCEPTED.
  // This matches the spec (PascalCase for React components).
});

test('isSnakeCase accepts valid', () => {
  assert.ok(isSnakeCase('foo'));
  assert.ok(isSnakeCase('foo_bar'));
  assert.ok(isSnakeCase('foo_bar_baz'));
  assert.ok(isSnakeCase('retrieve_node'));
});

test('isSnakeCase rejects invalid', () => {
  assert.ok(!isSnakeCase('FooBar'));
  assert.ok(!isSnakeCase('foo-bar'));
  assert.ok(!isSnakeCase('fooBar'));
  assert.ok(!isSnakeCase('foo__bar'));
});

test('isIsoDate accepts valid YYYY-MM-DD', () => {
  assert.ok(isIsoDate('2026-09-02'));
  assert.ok(isIsoDate('2024-02-29')); // leap year
  assert.ok(isIsoDate('2026-01-01'));
});

test('isIsoDate rejects invalid', () => {
  assert.ok(!isIsoDate('2026-9-2'));    // single-digit
  assert.ok(!isIsoDate('20260902'));     // no dashes
  assert.ok(!isIsoDate('2026-13-01'));   // bad month
  assert.ok(!isIsoDate('2026-02-30'));   // bad day for Feb
  assert.ok(!isIsoDate('2023-02-29'));   // not leap year
  assert.ok(!isIsoDate(''));
});
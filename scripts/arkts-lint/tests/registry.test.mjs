/**
 * registry.test.mjs — Tests for the rule registry
 *
 * Run with: node --test tests/registry.test.mjs
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { loadAllRules, validateRule } from '../rules/registry.mjs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const BASE_DIR = join(__dirname, '..');

test('loadAllRules: loads all rules without errors', async () => {
  const { rules, errors } = await loadAllRules(BASE_DIR);
  assert.equal(errors.length, 0, `Load errors: ${errors.join('\n')}`);
  assert.ok(rules.length >= 30, `Expected ≥30 rules, got ${rules.length}`);
});

test('loadAllRules: all rule IDs are unique', async () => {
  const { rules } = await loadAllRules(BASE_DIR);
  const ids = rules.map(r => r.id);
  const unique = new Set(ids);
  assert.equal(unique.size, ids.length, `Duplicate rule IDs: ${ids.length - unique.size}`);
});

test('loadAllRules: all rules have required fields', async () => {
  const { rules } = await loadAllRules(BASE_DIR);
  for (const rule of rules) {
    const errors = validateRule(rule, 'test');
    assert.deepEqual(errors, [], `Rule ${rule.id} has validation errors: ${errors.join(', ')}`);
  }
});

test('loadAllRules: all rules have non-empty fixHint', async () => {
  const { rules } = await loadAllRules(BASE_DIR);
  for (const rule of rules) {
    assert.ok(rule.fixHint && rule.fixHint.length > 0, `Rule ${rule.id} has empty fixHint`);
  }
});

test('loadAllRules: official rules use 10605xxx error codes', async () => {
  const { rules } = await loadAllRules(BASE_DIR);
  const officialRules = rules.filter(r => !r.code.startsWith('project-'));
  for (const rule of officialRules) {
    assert.ok(
      /^10605\d{3}$/.test(rule.code),
      `Rule ${rule.id} has non-conforming code: ${rule.code}`
    );
  }
});

test('loadAllRules: project rules have project-pref code', async () => {
  const { rules } = await loadAllRules(BASE_DIR);
  const projectRules = rules.filter(r => r.id.startsWith('struct-') || r.id.startsWith('no-'));
  for (const rule of projectRules) {
    assert.equal(rule.code, 'project-pref', `Rule ${rule.id} should have project-pref code`);
  }
});

test('loadAllRules: all rules have non-empty matches array', async () => {
  const { rules } = await loadAllRules(BASE_DIR);
  for (const rule of rules) {
    assert.ok(
      Array.isArray(rule.matches) && rule.matches.length > 0,
      `Rule ${rule.id} has empty matches`
    );
  }
});
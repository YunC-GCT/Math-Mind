/**
 * scripts/naming-lint/tests/config-loader.test.mjs
 *
 * Unit tests for config-loader.mjs.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
  validateConfig,
  loadConfig,
  DEFAULT_CONFIG,
  DEFAULT_SKIP_DIRS,
} from '../config-loader.mjs';

test('DEFAULT_CONFIG has expected shape', () => {
  assert.equal(DEFAULT_CONFIG.version, '1.0');
  assert.deepEqual(DEFAULT_CONFIG.roots, ['docs', 'scripts']);
  assert.ok(DEFAULT_CONFIG.skip.dirs.includes('node_modules'));
});

test('validateConfig accepts empty object', () => {
  const out = validateConfig({});
  assert.deepEqual(out, {});
});

test('validateConfig accepts full config', () => {
  const out = validateConfig({
    roots: ['src', 'docs'],
    skip: { dirs: ['foo'], files: ['bar'], patterns: ['^_'] },
  });
  assert.deepEqual(out.roots, ['src', 'docs']);
  assert.deepEqual(out.skip.dirs, ['foo']);
});

test('validateConfig rejects non-object', () => {
  assert.throws(() => validateConfig('not an object'), /must be a JSON object/);
  assert.throws(() => validateConfig(null), /must be a JSON object/);
  assert.throws(() => validateConfig(42), /must be a JSON object/);
});

test('validateConfig rejects non-array roots', () => {
  assert.throws(() => validateConfig({ roots: 'docs' }), /roots must be an array/);
});

test('validateConfig rejects non-string root entries', () => {
  assert.throws(() => validateConfig({ roots: [42, 'docs'] }), /only strings/);
});

test('validateConfig rejects non-array skip lists', () => {
  assert.throws(() => validateConfig({ skip: { dirs: 'foo' } }), /must be an array/);
});

test('validateConfig rejects non-string skip entries', () => {
  assert.throws(() => validateConfig({ skip: { files: [42] } }), /only strings/);
});

test('loadConfig returns DEFAULT_CONFIG when no file exists', () => {
  // create a temp dir with no config file
  const tmp = mkdtempSync(join(tmpdir(), 'naminglint-'));
  try {
    const out = loadConfig(join(tmp, 'nonexistent.json'));
    assert.equal(out.roots.length, DEFAULT_CONFIG.roots.length);
    assert.ok(out.skip.dirs.includes('node_modules'));
  } finally {
    rmSync(tmp, { recursive: true, force: true });
  }
});

test('loadConfig merges additive skip lists', () => {
  const tmp = mkdtempSync(join(tmpdir(), 'naminglint-'));
  try {
    const configPath = join(tmp, '.naminglintrc.json');
    writeFileSync(configPath, JSON.stringify({
      roots: ['src'],
      skip: { dirs: ['vendor', 'custom-skip'], files: ['.bak'] },
    }));
    const out = loadConfig(configPath);
    // roots fully replaced
    assert.deepEqual(out.roots, ['src']);
    // skip lists additive: defaults + user additions
    assert.ok(out.skip.dirs.includes('node_modules'), 'should keep default');
    assert.ok(out.skip.dirs.includes('vendor'), 'should add user entry');
    assert.ok(out.skip.dirs.includes('custom-skip'), 'should add user entry');
    assert.ok(out.skip.files.includes('.DS_Store'), 'should keep default file');
    assert.ok(out.skip.files.includes('.bak'), 'should add user file');
  } finally {
    rmSync(tmp, { recursive: true, force: true });
  }
});

test('loadConfig defaults roots when not specified', () => {
  const tmp = mkdtempSync(join(tmpdir(), 'naminglint-'));
  try {
    const configPath = join(tmp, '.naminglintrc.json');
    writeFileSync(configPath, JSON.stringify({ skip: { dirs: ['extra'] } }));
    const out = loadConfig(configPath);
    assert.deepEqual(out.roots, DEFAULT_CONFIG.roots);
  } finally {
    rmSync(tmp, { recursive: true, force: true });
  }
});

test('loadConfig throws on malformed JSON', () => {
  const tmp = mkdtempSync(join(tmpdir(), 'naminglint-'));
  try {
    const configPath = join(tmp, '.naminglintrc.json');
    writeFileSync(configPath, '{ not valid json');
    assert.throws(() => loadConfig(configPath), /failed to parse config/);
  } finally {
    rmSync(tmp, { recursive: true, force: true });
  }
});

test('loadConfig throws on schema violation', () => {
  const tmp = mkdtempSync(join(tmpdir(), 'naminglint-'));
  try {
    const configPath = join(tmp, '.naminglintrc.json');
    writeFileSync(configPath, JSON.stringify({ roots: 'docs' })); // not array
    assert.throws(() => loadConfig(configPath), /roots must be an array/);
  } finally {
    rmSync(tmp, { recursive: true, force: true });
  }
});

test('loadConfig returns frozen result', () => {
  const out = loadConfig(null);
  assert.ok(Object.isFrozen(out), 'config should be frozen');
  assert.ok(Object.isFrozen(out.roots), 'roots should be frozen');
  assert.ok(Object.isFrozen(out.skip), 'skip should be frozen');
  assert.ok(Object.isFrozen(out.skip.dirs), 'skip.dirs should be frozen');
});

test('DEFAULT_SKIP_DIRS contains expected entries', () => {
  for (const expected of ['node_modules', '.git', '_fetched', '__generated__', 'vendor']) {
    assert.ok(DEFAULT_SKIP_DIRS.includes(expected), `should include ${expected}`);
  }
});
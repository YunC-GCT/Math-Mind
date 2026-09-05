import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '../../..');
const dispatcher = readFileSync(resolve(root, 'agents/src/main/ets/core/Dispatcher.ets'), 'utf8');

test('Dispatcher keeps compatibility wrappers but one request path', () => {
  assert.match(dispatcher, /async dispatch\(/);
  assert.match(dispatcher, /async analyze\(/);
  assert.match(dispatcher, /async routeDispatch\(/);
  assert.match(dispatcher, /private async analyzeRequest\(/);
  assert.match(dispatcher, /private async dispatchRequest\(/);
  assert.equal((dispatcher.match(/async dispatch\(/g) || []).length, 1);
  assert.equal((dispatcher.match(/private async dispatchRequest\(/g) || []).length, 1);
});

test('Dispatcher has one dependency instance per request path', () => {
  assert.equal((dispatcher.match(/new TypeClassifier\(/g) || []).length, 2);
  assert.equal((dispatcher.match(/new KnowledgeModel\(/g) || []).length, 1);
});

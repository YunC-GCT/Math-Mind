/**
 * rules/registry.mjs — Load all rules from ./official/ + ./project/
 *
 * Validation: each rule file must export a default object with all required fields.
 *
 * Validation is run by the engine (index.mjs) via --check-rules flag.
 */

import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, extname, basename } from 'node:path';
import { pathToFileURL } from 'node:url';

const REQUIRED_FIELDS = ['id', 'code', 'severity', 'title', 'fixHint', 'matches', 'check'];

/**
 * Load all rule modules from a directory.
 * Returns { rules, errors } — errors is populated if a rule file is malformed.
 */
export async function loadRulesFromDir(dir) {
  const rules = [];
  const errors = [];
  let entries;
  try {
    entries = readdirSync(dir);
  } catch (e) {
    return { rules, errors: [`Cannot read rules dir ${dir}: ${e.message}`] };
  }
  for (const entry of entries) {
    if (!entry.endsWith('.mjs')) continue;
    if (entry.startsWith('_')) continue; // skip _template.mjs
    const fullPath = join(dir, entry);
    try {
      const stat = statSync(fullPath);
      if (!stat.isFile()) continue;
    } catch {
      continue;
    }
    try {
      const mod = await import(pathToFileURL(fullPath).href);
      const rule = mod.default;
      if (!rule) {
        errors.push(`${entry}: no default export`);
        continue;
      }
      const missing = REQUIRED_FIELDS.filter(f => !(f in rule));
      if (missing.length > 0) {
        errors.push(`${entry}: missing ${missing.join(', ')}`);
        continue;
      }
      rules.push(rule);
    } catch (e) {
      errors.push(`${entry}: import failed: ${e.message}`);
    }
  }
  return { rules, errors };
}

/**
 * Validate a single rule's metadata.
 * Returns array of error strings (empty if valid).
 */
export function validateRule(rule, file = '?') {
  const errors = [];
  const tag = `${rule.id ?? '(no id)'} [${file}]`;
  if (!rule.id) errors.push(`${tag}: missing id`);
  if (!rule.code) errors.push(`${tag}: missing code`);
  if (!['error', 'warn'].includes(rule.severity)) errors.push(`${tag}: severity must be error|warn`);
  if (!rule.title) errors.push(`${tag}: missing title`);
  if (!rule.fixHint) errors.push(`${tag}: missing fixHint`);
  if (!Array.isArray(rule.matches)) errors.push(`${tag}: matches must be array`);
  if (typeof rule.check !== 'function') errors.push(`${tag}: check must be function`);
  if (rule.code && !rule.code.startsWith('10605') && rule.code !== 'project-pref') {
    errors.push(`${tag}: code '${rule.code}' should be 10605xxx or 'project-pref'`);
  }
  return errors;
}

/**
 * Load all rules from both official/ and project/.
 */
export async function loadAllRules(baseDir) {
  const official = await loadRulesFromDir(join(baseDir, 'rules', 'official'));
  const project = await loadRulesFromDir(join(baseDir, 'rules', 'project'));
  const rules = [...official.rules, ...project.rules];
  const errors = [...official.errors, ...project.errors];

  // Check for duplicate IDs
  const seen = new Set();
  for (const r of rules) {
    if (seen.has(r.id)) {
      errors.push(`Duplicate rule id: ${r.id}`);
    }
    seen.add(r.id);
  }

  return { rules, errors };
}
/**
 * scripts/naming-lint/config-loader.mjs
 *
 * Loads and validates .naminglintrc.json (project config) with defaults.
 * The config can ADD to skip lists but cannot remove defaults (safety).
 * Roots, if provided, fully replace defaults.
 *
 * Schema:
 *   {
 *     "version": "1.0",
 *     "roots": ["docs", "scripts"],                // full override
 *     "skip": {
 *       "dirs":     ["vendor", ...],               // additive to defaults
 *       "files":    [".bak", ...],                // additive to defaults
 *       "patterns": ["^_", ...]                   // regex matched against basename
 *     }
 *   }
 *
 * Returns a frozen Config object usable by the walker.
 */

import { readFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = join(__dirname, '..', '..');

/** Default skip lists (built into the tool, no override possible). */
const DEFAULT_SKIP_DIRS = Object.freeze([
  'node_modules', '.git', '.hvigor', 'build', 'oh_modules', 'dist',
  '.reasonix', '_fetched', '.appanalyzer', '__generated__', 'vendor',
  'third_party', '.appanalyzer',
]);
const DEFAULT_SKIP_FILES = Object.freeze([
  '.DS_Store', 'Thumbs.db', 'desktop.ini',
]);
const DEFAULT_SKIP_PATTERNS = Object.freeze([
  '^_',  // files starting with _ (scaffolds)
]);
const DEFAULT_ROOTS = Object.freeze(['docs', 'scripts']);

/** Default config (used when no .naminglintrc.json exists). */
const DEFAULT_CONFIG = Object.freeze({
  version: '1.0',
  roots: DEFAULT_ROOTS,
  skip: {
    dirs: DEFAULT_SKIP_DIRS,
    files: DEFAULT_SKIP_FILES,
    patterns: DEFAULT_SKIP_PATTERNS,
  },
});

/**
 * Find the config file. Search order:
 *   1. .naminglintrc.json (project root)
 *   2. .naminglintrc (no extension)
 *   3. naming-lint.config.json
 *   4. --config flag (caller-provided)
 *
 * Returns the path to the first found config, or null.
 */
export function findConfig(customPath) {
  if (customPath) {
    return existsSync(customPath) ? customPath : null;
  }
  const candidates = ['.naminglintrc.json', '.naminglintrc', 'naming-lint.config.json'];
  for (const c of candidates) {
    const p = join(REPO_ROOT, c);
    if (existsSync(p)) return p;
  }
  return null;
}

/**
 * Validate a parsed config object. Throws on invalid schema.
 * Returns the validated (but unmerged) config.
 */
export function validateConfig(parsed) {
  if (typeof parsed !== 'object' || parsed === null) {
    throw new Error('config must be a JSON object');
  }
  if (parsed.roots !== undefined && !Array.isArray(parsed.roots)) {
    throw new Error('config.roots must be an array of strings');
  }
  if (parsed.roots !== undefined && !parsed.roots.every((r) => typeof r === 'string')) {
    throw new Error('config.roots must contain only strings');
  }
  if (parsed.skip !== undefined) {
    if (typeof parsed.skip !== 'object' || parsed.skip === null) {
      throw new Error('config.skip must be a JSON object');
    }
    for (const key of ['dirs', 'files', 'patterns']) {
      if (parsed.skip[key] !== undefined && !Array.isArray(parsed.skip[key])) {
        throw new Error(`config.skip.${key} must be an array`);
      }
      if (parsed.skip[key] !== undefined && !parsed.skip[key].every((s) => typeof s === 'string')) {
        throw new Error(`config.skip.${key} must contain only strings`);
      }
    }
  }
  return parsed;
}

/**
 * Load .naminglintrc.json and merge with defaults.
 * If no config file exists, returns DEFAULT_CONFIG unchanged.
 * If config file is malformed, throws with a clear message.
 */
export function loadConfig(customPath) {
  const configPath = findConfig(customPath);
  if (!configPath) return DEFAULT_CONFIG;

  let raw;
  try {
    raw = readFileSync(configPath, 'utf8');
  } catch (err) {
    throw new Error(`failed to read config at ${configPath}: ${err.message}`);
  }

  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (err) {
    throw new Error(`failed to parse config JSON at ${configPath}: ${err.message}`);
  }

  const validated = validateConfig(parsed);

  // Merge: skip lists are additive, roots are full-replacement
  const merged = {
    version: validated.version ?? '1.0',
    roots: validated.roots ?? DEFAULT_ROOTS,
    skip: {
      dirs: [...DEFAULT_SKIP_DIRS, ...(validated.skip?.dirs ?? [])],
      files: [...DEFAULT_SKIP_FILES, ...(validated.skip?.files ?? [])],
      patterns: [...DEFAULT_SKIP_PATTERNS, ...(validated.skip?.patterns ?? [])],
    },
    source: configPath,
  };

  return Object.freeze({
    version: merged.version,
    roots: Object.freeze([...merged.roots]),
    skip: Object.freeze({
      dirs: Object.freeze([...merged.skip.dirs]),
      files: Object.freeze([...merged.skip.files]),
      patterns: Object.freeze([...merged.skip.patterns]),
    }),
    source: merged.source,
  });
}

export { DEFAULT_CONFIG, DEFAULT_ROOTS, DEFAULT_SKIP_DIRS, DEFAULT_SKIP_FILES, DEFAULT_SKIP_PATTERNS, REPO_ROOT };
/**
 * scripts/naming-lint/rule-checkers.mjs
 *
 * Pure-rule helpers (no filesystem). Extracted from index.mjs so tests can
 * import them without triggering the main() walk.
 */

/**
 * kebab-case (relaxed): lowercase, digits, single dashes, dots for version
 * numbers (e.g. `1.1`, `1.0.0`). Used for docs and configs.
 */
export function isKebabCase(s) {
  return /^[a-z0-9]+(([-.][a-z0-9]+)*)$/.test(s);
}

/** PascalCase for React components: starts uppercase, no spaces, no dashes. */
export function isPascalCase(s) {
  return /^[A-Z][a-zA-Z0-9]*$/.test(s);
}

/** snake_case: lowercase, digits, single underscores. */
export function isSnakeCase(s) {
  return /^[a-z0-9]+(_[a-z0-9]+)*$/.test(s);
}

/** YYYY-MM-DD format, valid month + day-of-month. */
export function isIsoDate(s) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) return false;
  const [y, m, d] = s.split('-').map(Number);
  if (m < 1 || m > 12) return false;
  if (d < 1 || d > 31) return false;
  // Day-of-month sanity (use new Date to validate)
  const dt = new Date(Date.UTC(y, m - 1, d));
  return dt.getUTCFullYear() === y && dt.getUTCMonth() === m - 1 && dt.getUTCDate() === d;
}
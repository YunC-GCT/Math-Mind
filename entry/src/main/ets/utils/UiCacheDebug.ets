/**
 * UiCacheDebug.ets - gated debug logging for UI caches
 *
 * Path: entry/src/main/ets/utils/UiCacheDebug.ets
 * Responsibility: Keep cache hit/miss diagnostics available without logging in normal runs.
 * Dependencies: none.
 *
 * Data flow:
 *   cache modules -> uiCacheLog / uiCacheWarn -> console only when UI_CACHE_DEBUG is true
 *
 * ArkTS 1.1 strict:
 *   - Explicit string parameters
 *   - No framework dependencies
 */

const UI_CACHE_DEBUG: boolean = false

export function uiCacheLog(message: string): void {
  if (UI_CACHE_DEBUG) {
    console.info(message)
  }
}

export function uiCacheWarn(message: string): void {
  if (UI_CACHE_DEBUG) {
    console.warn(message)
  }
}

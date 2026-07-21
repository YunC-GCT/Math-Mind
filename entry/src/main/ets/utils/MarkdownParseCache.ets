/**
 * MarkdownParseCache.ets - LRU cache for parsed markdown blocks and inline spans
 *
 * Path: entry/src/main/ets/utils/MarkdownParseCache.ets
 * Responsibility: Avoid repeated Markdown parsing for detail content opened multiple times.
 * Dependencies: MarkdownParser, MarkdownInlineParser.
 *
 * Data flow:
 *   MarkdownRenderer -> cachedParseMarkdown / cachedParseMarkdownInline -> parser on cache miss
 *
 * ArkTS 1.1 strict:
 *   - Explicit types throughout
 *   - Iteration uses for...of and while
 */

import { parseMarkdown, MarkdownBlock } from "./MarkdownParser"
import { parseMarkdownInline, MarkdownInlineSegment } from "./MarkdownInlineParser"
import { uiCacheLog } from "./UiCacheDebug"

class MarkdownBlockEntry {
  key: string = ""
  value: MarkdownBlock[] = []
  touched: number = 0
  touchedAt: number = 0

  constructor(key: string, value: MarkdownBlock[], touched: number, touchedAt: number) {
    this.key = key
    this.value = value
    this.touched = touched
    this.touchedAt = touchedAt
  }
}

class MarkdownInlineEntry {
  key: string = ""
  value: MarkdownInlineSegment[] = []
  touched: number = 0
  touchedAt: number = 0

  constructor(key: string, value: MarkdownInlineSegment[], touched: number, touchedAt: number) {
    this.key = key
    this.value = value
    this.touched = touched
    this.touchedAt = touchedAt
  }
}

const MARKDOWN_BLOCK_CACHE: MarkdownBlockEntry[] = []
const MARKDOWN_INLINE_CACHE: MarkdownInlineEntry[] = []
const MARKDOWN_CACHE_LIMIT: number = 96
const MARKDOWN_CACHE_TTL_MS: number = 10 * 60 * 1000
let markdownCacheClock: number = 0

function nextMarkdownTick(): number {
  markdownCacheClock += 1
  return markdownCacheClock
}

function markdownHash(text: string): string {
  let hash: number = 5381
  let index: number = 0
  while (index < text.length) {
    hash = ((hash << 5) + hash + text.charCodeAt(index)) | 0
    index += 1
  }
  const positive: number = hash < 0 ? -hash : hash
  return text.length.toString() + "_" + positive.toString()
}

export function cachedParseMarkdown(text: string): MarkdownBlock[] {
  const key: string = markdownHash(text)
  const now: number = Date.now()
  trimBlockCache(now)
  for (const entry of MARKDOWN_BLOCK_CACHE) {
    if (entry.key === key) {
      entry.touched = nextMarkdownTick()
      entry.touchedAt = now
      uiCacheLog("[UiDataCache] markdown hit kind=block key=" + key)
      return entry.value
    }
  }
  uiCacheLog("[UiDataCache] markdown miss kind=block key=" + key)
  const value: MarkdownBlock[] = parseMarkdown(text)
  MARKDOWN_BLOCK_CACHE.push(new MarkdownBlockEntry(key, value, nextMarkdownTick(), now))
  trimBlockCache(now)
  return value
}

export function cachedParseMarkdownInline(text: string): MarkdownInlineSegment[] {
  const key: string = markdownHash(text)
  const now: number = Date.now()
  trimInlineCache(now)
  for (const entry of MARKDOWN_INLINE_CACHE) {
    if (entry.key === key) {
      entry.touched = nextMarkdownTick()
      entry.touchedAt = now
      uiCacheLog("[UiDataCache] markdown hit kind=inline key=" + key)
      return entry.value
    }
  }
  uiCacheLog("[UiDataCache] markdown miss kind=inline key=" + key)
  const value: MarkdownInlineSegment[] = parseMarkdownInline(text)
  MARKDOWN_INLINE_CACHE.push(new MarkdownInlineEntry(key, value, nextMarkdownTick(), now))
  trimInlineCache(now)
  return value
}

export function invalidateMarkdownText(text: string): void {
  const key: string = markdownHash(text)
  removeBlockKey(key)
  removeInlineKey(key)
}

function trimBlockCache(now: number): void {
  dropExpiredBlockEntries(now)
  while (MARKDOWN_BLOCK_CACHE.length > MARKDOWN_CACHE_LIMIT) {
    removeOldestBlockEntry()
  }
}

function trimInlineCache(now: number): void {
  dropExpiredInlineEntries(now)
  while (MARKDOWN_INLINE_CACHE.length > MARKDOWN_CACHE_LIMIT) {
    removeOldestInlineEntry()
  }
}

function dropExpiredBlockEntries(now: number): void {
  let index: number = MARKDOWN_BLOCK_CACHE.length - 1
  while (index >= 0) {
    if (now - MARKDOWN_BLOCK_CACHE[index].touchedAt > MARKDOWN_CACHE_TTL_MS) {
      MARKDOWN_BLOCK_CACHE.splice(index, 1)
    }
    index -= 1
  }
}

function dropExpiredInlineEntries(now: number): void {
  let index: number = MARKDOWN_INLINE_CACHE.length - 1
  while (index >= 0) {
    if (now - MARKDOWN_INLINE_CACHE[index].touchedAt > MARKDOWN_CACHE_TTL_MS) {
      MARKDOWN_INLINE_CACHE.splice(index, 1)
    }
    index -= 1
  }
}

function removeOldestBlockEntry(): void {
  if (MARKDOWN_BLOCK_CACHE.length === 0) {
    return
  }
  let oldestIndex: number = 0
  let oldestTick: number = MARKDOWN_BLOCK_CACHE[0].touched
  let index: number = 1
  while (index < MARKDOWN_BLOCK_CACHE.length) {
    if (MARKDOWN_BLOCK_CACHE[index].touched < oldestTick) {
      oldestTick = MARKDOWN_BLOCK_CACHE[index].touched
      oldestIndex = index
    }
    index += 1
  }
  MARKDOWN_BLOCK_CACHE.splice(oldestIndex, 1)
  uiCacheLog("[UiDataCache] evict markdown kind=block")
}

function removeOldestInlineEntry(): void {
  if (MARKDOWN_INLINE_CACHE.length === 0) {
    return
  }
  let oldestIndex: number = 0
  let oldestTick: number = MARKDOWN_INLINE_CACHE[0].touched
  let index: number = 1
  while (index < MARKDOWN_INLINE_CACHE.length) {
    if (MARKDOWN_INLINE_CACHE[index].touched < oldestTick) {
      oldestTick = MARKDOWN_INLINE_CACHE[index].touched
      oldestIndex = index
    }
    index += 1
  }
  MARKDOWN_INLINE_CACHE.splice(oldestIndex, 1)
  uiCacheLog("[UiDataCache] evict markdown kind=inline")
}

function removeBlockKey(key: string): void {
  let index: number = MARKDOWN_BLOCK_CACHE.length - 1
  while (index >= 0) {
    if (MARKDOWN_BLOCK_CACHE[index].key === key) {
      MARKDOWN_BLOCK_CACHE.splice(index, 1)
    }
    index -= 1
  }
}

function removeInlineKey(key: string): void {
  let index: number = MARKDOWN_INLINE_CACHE.length - 1
  while (index >= 0) {
    if (MARKDOWN_INLINE_CACHE[index].key === key) {
      MARKDOWN_INLINE_CACHE.splice(index, 1)
    }
    index -= 1
  }
}

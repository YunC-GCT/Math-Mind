// ============================================================================
//  shared/components/MathTextRenderer.ets - KaTeX Web renderer wrapper
// ============================================================================

import {
  TEXT, TEXT_2, GLASS_10, BORDER,
  F_BASE,
  LatexRiskNormalizer,
} from 'common'
import type { LatexRiskResult } from 'common'
import webview from '@ohos.web.webview'
import { uiCacheLog } from '../../utils/UiCacheDebug'

class MathRenderCacheEntry {
  key: string = ''
  encodedHtml: string = ''
  height: number = 0
  touched: number = 0
  touchedAt: number = 0
  size: number = 0

  constructor(key: string, encodedHtml: string, height: number, touched: number, touchedAt: number) {
    this.key = key
    this.encodedHtml = encodedHtml
    this.height = height
    this.touched = touched
    this.touchedAt = touchedAt
    this.size = encodedHtml.length
  }
}

class MathRenderPayload {
  height: number = 0
  encodedHtml: string = ''
}

const MATH_RENDER_CACHE: MathRenderCacheEntry[] = []
const MATH_RENDER_CACHE_LIMIT: number = 64
const MATH_RENDER_CACHE_MAX_CHARS: number = 600000
const MATH_RENDER_CACHE_TTL_MS: number = 10 * 60 * 1000
const MATH_RENDER_CACHE_PASSIVE_TRIM_TICKS: number = 12
const NOTE_MATH_RENDER_DEFER_BASE_MS: number = 24
const NOTE_MATH_RENDER_DEFER_STEP_MS: number = 22
const NOTE_MATH_RENDER_DEFER_SLOTS: number = 8
let mathRenderCacheClock: number = 0
let noteMathRenderDeferClock: number = 0

function nextCacheTick(): number {
  mathRenderCacheClock += 1
  return mathRenderCacheClock
}

function nextNoteMathRenderDelay(): number {
  const slot: number = noteMathRenderDeferClock % NOTE_MATH_RENDER_DEFER_SLOTS
  noteMathRenderDeferClock += 1
  return NOTE_MATH_RENDER_DEFER_BASE_MS + slot * NOTE_MATH_RENDER_DEFER_STEP_MS
}

function cacheGet(key: string): MathRenderCacheEntry | null {
  const now: number = Date.now()
  trimCacheIfNeeded(now)
  for (const entry of MATH_RENDER_CACHE) {
    if (entry.key === key) {
      entry.touched = nextCacheTick()
      entry.touchedAt = now
      uiCacheLog('[UiDataCache] math hit key=' + key)
      return entry
    }
  }
  uiCacheLog('[UiDataCache] math miss key=' + key)
  return null
}

function cacheSet(key: string, encodedHtml: string, height: number): void {
  const now: number = Date.now()
  const touched: number = nextCacheTick()
  if (encodedHtml.length > MATH_RENDER_CACHE_MAX_CHARS) {
    cacheRemove(key)
    trimCache(now)
    return
  }
  for (const entry of MATH_RENDER_CACHE) {
    if (entry.key === key) {
      entry.encodedHtml = encodedHtml
      entry.height = height
      entry.touched = touched
      entry.touchedAt = now
      entry.size = encodedHtml.length
      trimCacheIfNeeded(now)
      return
    }
  }
  MATH_RENDER_CACHE.push(new MathRenderCacheEntry(key, encodedHtml, height, touched, now))
  trimCache(now)
}

function cacheRemove(key: string): void {
  let index: number = MATH_RENDER_CACHE.length - 1
  while (index >= 0) {
    if (MATH_RENDER_CACHE[index].key === key) {
      MATH_RENDER_CACHE.splice(index, 1)
    }
    index -= 1
  }
}

function trimCacheIfNeeded(now: number): void {
  if (MATH_RENDER_CACHE.length > MATH_RENDER_CACHE_LIMIT
    || mathRenderCacheClock % MATH_RENDER_CACHE_PASSIVE_TRIM_TICKS === 0) {
    trimCache(now)
  }
}

function trimCache(now: number): void {
  dropExpiredCacheEntries(now)
  while (MATH_RENDER_CACHE.length > MATH_RENDER_CACHE_LIMIT) {
    removeOldestCacheEntry()
  }
  while (cacheTotalSize() > MATH_RENDER_CACHE_MAX_CHARS && MATH_RENDER_CACHE.length > 0) {
    removeOldestCacheEntry()
  }
}

function dropExpiredCacheEntries(now: number): void {
  let index: number = MATH_RENDER_CACHE.length - 1
  while (index >= 0) {
    if (now - MATH_RENDER_CACHE[index].touchedAt > MATH_RENDER_CACHE_TTL_MS) {
      MATH_RENDER_CACHE.splice(index, 1)
    }
    index -= 1
  }
}

function removeOldestCacheEntry(): void {
  if (MATH_RENDER_CACHE.length === 0) {
    return
  }
  let oldestIndex: number = 0
  let oldestTick: number = MATH_RENDER_CACHE[0].touched
  let index: number = 1
  while (index < MATH_RENDER_CACHE.length) {
    if (MATH_RENDER_CACHE[index].touched < oldestTick) {
      oldestTick = MATH_RENDER_CACHE[index].touched
      oldestIndex = index
    }
    index += 1
  }
  MATH_RENDER_CACHE.splice(oldestIndex, 1)
}

function cacheTotalSize(): number {
  let total: number = 0
  for (const entry of MATH_RENDER_CACHE) {
    total += entry.size
  }
  return total
}

function contentHash(text: string): string {
  let hash: number = 5381
  let index: number = 0
  while (index < text.length) {
    hash = ((hash << 5) + hash + text.charCodeAt(index)) | 0
    index += 1
  }
  const positive: number = hash < 0 ? -hash : hash
  return text.length.toString() + '_' + positive.toString()
}

@Component
export struct MathTextRenderer {
  @Prop @Watch('onTextChanged') text: string = ''
  @Prop textColor: ResourceColor = TEXT_2
  @Prop formulaColor: ResourceColor = TEXT
  @Prop formulaBackground: ResourceColor = GLASS_10
  @Prop formulaBorder: ResourceColor = BORDER
  @Prop fontSize: number = F_BASE
  @Prop lineHeight: number = 24
  @Prop formulaFontSize: number = F_BASE
  @Prop formulaLineHeight: number = 24
  @Prop profile: 'chat' | 'chatUser' | 'note' | 'preview' = 'chat'
  @Prop forceDisplay: boolean = false
  @Prop minHeight: number = 42
  @Prop maxHeight: number = 1800

  private controller: webview.WebviewController = new webview.WebviewController()
  private lastAppliedKey: string = ''
  private riskNormalizer: LatexRiskNormalizer = new LatexRiskNormalizer()
  @State private pageReady: boolean = false
  @State private renderReady: boolean = true
  @State private webHeight: number = 42
  private renderSeq: number = 0

  aboutToAppear(): void {
    this.renderSeq += 1
    const seq: number = this.renderSeq
    const renderInput: LatexRiskResult = this.normalizeForRender(this.text)
    if (renderInput.renderMode === 'plainFallback') {
      this.renderReady = true
      this.webHeight = this.clampHeight(this.estimateHeight(renderInput.normalizedText))
      return
    }
    const markdown: string = this.prepareMarkdownFromResult(renderInput)
    const cached: MathRenderCacheEntry | null = cacheGet(this.cacheKey(markdown))
    if (cached !== null) {
      this.renderReady = true
      this.webHeight = this.clampHeight(cached.height)
      return
    }
    if (this.shouldDeferWebRender()) {
      this.renderReady = false
      this.pageReady = false
      this.scheduleDeferredWebRender(seq)
    } else {
      this.renderReady = true
    }
    this.webHeight = this.estimateHeight(markdown)
  }

  aboutToDisappear(): void {
    this.renderSeq += 1
  }

  onTextChanged(): void {
    this.renderSeq += 1
    const seq: number = this.renderSeq
    const renderInput: LatexRiskResult = this.normalizeForRender(this.text)
    if (renderInput.renderMode === 'plainFallback') {
      this.lastAppliedKey = ''
      this.renderReady = true
      this.webHeight = this.clampHeight(this.estimateHeight(renderInput.normalizedText))
      return
    }
    const markdown: string = this.prepareMarkdownFromResult(renderInput)
    const cacheKey: string = this.cacheKey(markdown)
    const cached: MathRenderCacheEntry | null = cacheGet(cacheKey)
    if (cached !== null) {
      this.renderReady = true
      this.webHeight = this.clampHeight(cached.height)
      if (this.pageReady) {
        this.applyCachedRender(cacheKey, cached)
      }
      return
    }
    this.webHeight = this.estimateHeight(markdown)
    if (this.shouldDeferWebRender()) {
      this.renderReady = false
      this.pageReady = false
      this.scheduleDeferredWebRender(seq)
      return
    }
    this.renderReady = true
    if (this.pageReady) {
      this.renderContent()
    }
  }

  private renderContent = (): void => {
    const renderInput: LatexRiskResult = this.normalizeForRender(this.text)
    if (renderInput.renderMode === 'plainFallback') {
      return
    }
    const markdown: string = this.prepareMarkdownFromResult(renderInput)
    const cacheKey: string = this.cacheKey(markdown)
    if (cacheKey === this.lastAppliedKey) {
      return
    }
    const cached: MathRenderCacheEntry | null = cacheGet(cacheKey)
    if (cached !== null) {
      this.webHeight = this.clampHeight(cached.height)
      this.applyCachedRender(cacheKey, cached)
      return
    }
    const script: string = 'renderForCache(' + JSON.stringify(markdown) + ',' + JSON.stringify(this.profile) + ')'
    this.webHeight = this.estimateHeight(markdown)
    this.controller.runJavaScript(script)
      .then((heightText: string): void => {
        if (cacheKey !== this.currentCacheKey()) {
          return
        }
        const payload: MathRenderPayload = this.parseRenderPayload(heightText)
        if (payload.height > 0) {
          const height: number = this.clampHeight(payload.height + 2)
          this.webHeight = height
          this.lastAppliedKey = cacheKey
          if (payload.encodedHtml.length > 0) {
            cacheSet(cacheKey, payload.encodedHtml, height)
          }
        }
      })
      .catch((_err: Error): void => {})
  }

  private applyCachedRender = (cacheKey: string, cached: MathRenderCacheEntry): void => {
    const script: string = 'applyCached(' + JSON.stringify(cached.encodedHtml) + ',' + JSON.stringify(this.profile) + ')'
    this.controller.runJavaScript(script)
      .then((heightText: string): void => {
        if (cacheKey !== this.currentCacheKey()) {
          return
        }
        const parsed: number = this.parseRenderedHeight(heightText)
        if (!Number.isNaN(parsed) && parsed > 0) {
          const height: number = this.clampHeight(parsed + 2)
          this.webHeight = height
          cached.height = height
        }
        this.lastAppliedKey = cacheKey
      })
      .catch((_err: Error): void => {})
  }

  private parseRenderedHeight = (heightText: string): number => {
    let raw: string = heightText.trim()
    if (raw.startsWith('"') && raw.endsWith('"') && raw.length >= 2) {
      raw = raw.substring(1, raw.length - 1)
    }
    return Number(raw)
  }

  private parseRenderPayload = (payloadText: string): MathRenderPayload => {
    const payload: MathRenderPayload = new MathRenderPayload()
    const raw: string = this.unwrapJavaScriptString(payloadText)
    const splitIndex: number = raw.indexOf('\n')
    if (splitIndex < 0) {
      payload.height = Number(raw.trim())
      return payload
    }
    payload.height = Number(raw.substring(0, splitIndex).trim())
    payload.encodedHtml = raw.substring(splitIndex + 1)
    return payload
  }

  private unwrapJavaScriptString = (value: string): string => {
    let raw: string = value.trim()
    if (raw.startsWith('"') && raw.endsWith('"') && raw.length >= 2) {
      raw = raw.substring(1, raw.length - 1)
      raw = raw.replace(/\\n/g, '\n')
      raw = raw.replace(/\\"/g, '"')
      raw = raw.replace(/\\\\/g, '\\')
    }
    return raw
  }

  private cacheKey = (markdown: string): string => {
    return this.profile + '|' + (this.forceDisplay ? '1' : '0') + '|' + contentHash(markdown)
  }

  private currentCacheKey = (): string => {
    const renderInput: LatexRiskResult = this.normalizeForRender(this.text)
    if (renderInput.renderMode === 'plainFallback') {
      return ''
    }
    return this.cacheKey(this.prepareMarkdownFromResult(renderInput))
  }

  private clampHeight = (height: number): number => {
    return Math.max(this.minHeight, Math.min(this.maxHeight, height))
  }

  private normalizeForRender = (raw: string): LatexRiskResult => {
    const normalized: string = raw.replace(/\r\n/g, '\n').replace(/\r/g, '\n').trim()
    if (normalized.length === 0) {
      return this.riskNormalizer.normalize('')
    }
    if (this.forceDisplay) {
      return this.riskNormalizer.normalize('$$\n' + this.stripDisplayFence(normalized) + '\n$$')
    }
    return this.riskNormalizer.normalize(normalized)
  }

  private prepareMarkdownFromResult = (renderInput: LatexRiskResult): string => {
    const normalized: string = renderInput.normalizedText.trim()
    if (normalized.length === 0) {
      return ''
    }
    return this.wrapFormulaOnlyLines(normalized)
  }

  private plainFallbackText = (): string => {
    const renderInput: LatexRiskResult = this.normalizeForRender(this.text)
    const normalized: string = renderInput.normalizedText.trim()
    return normalized.length > 0 ? normalized : this.text.trim()
  }

  private shouldDeferWebRender = (): boolean => {
    return this.profile === 'note'
  }

  private scheduleDeferredWebRender = (seq: number): void => {
    const delay: number = nextNoteMathRenderDelay()
    setTimeout((): void => {
      if (seq !== this.renderSeq) {
        return
      }
      this.renderReady = true
      if (this.pageReady) {
        this.renderContent()
      }
    }, delay)
  }

  private stripDisplayFence = (raw: string): string => {
    let text: string = raw.trim()
    if (text.startsWith('$$') && text.endsWith('$$') && text.length > 4) {
      text = text.substring(2, text.length - 2).trim()
    }
    if (text.startsWith('\\[') && text.endsWith('\\]') && text.length > 4) {
      text = text.substring(2, text.length - 2).trim()
    }
    return text
  }

  private wrapFormulaOnlyLines = (raw: string): string => {
    const lines: string[] = raw.split('\n')
    const result: string[] = []
    for (const line of lines) {
      const trimmed: string = line.trim()
      if (this.shouldWrapDisplayFormula(trimmed)) {
        result.push('$$' + trimmed + '$$')
      } else {
        result.push(line)
      }
    }
    return result.join('\n')
  }

  private shouldWrapDisplayFormula = (line: string): boolean => {
    if (line.length === 0) {
      return false
    }
    if (line.indexOf('$') >= 0 || line.indexOf('\\(') >= 0 || line.indexOf('\\[') >= 0) {
      return false
    }
    const hasMathCommand: boolean = line.indexOf('\\frac') >= 0
      || line.indexOf('\\sqrt') >= 0
      || line.indexOf('\\sum') >= 0
      || line.indexOf('\\int') >= 0
      || line.indexOf('\\lim') >= 0
      || line.indexOf('\\begin') >= 0
    if (!hasMathCommand) {
      return false
    }
    return (line.indexOf('\uFF0C') < 0
      && line.indexOf('\u3002') < 0
      && line.indexOf('\uFF1B') < 0
      && line.indexOf('\uFF1A') < 0
      && line.indexOf(' ') < 0) || line.indexOf('=') >= 0
  }

  private estimateHeight = (preparedMarkdown: string): number => {
    const normalized: string = preparedMarkdown.replace(/\r\n/g, '\n').trim()
    if (normalized.length === 0) {
      return 1
    }
    const charsPerLine: number = this.profile === 'note' ? 24 : 20
    const baseLineHeight: number = this.profile === 'note' ? 28 : 22
    let lineCount: number = 0
    for (const line of normalized.split('\n')) {
      const visualLines: number = Math.max(1, Math.ceil(line.length / charsPerLine))
      lineCount += visualLines
    }
    const displayFormulaCount: number = Math.floor((normalized.split('$$').length - 1) / 2)
      + Math.floor((normalized.split('\\[').length - 1))
    const formulaExtra: number = displayFormulaCount * (this.profile === 'note' ? 42 : 34)
    const estimated: number = lineCount * baseLineHeight + formulaExtra + 18
    return this.clampHeight(estimated)
  }

  build() {
    if (this.normalizeForRender(this.text).renderMode === 'plainFallback') {
      Text(this.plainFallbackText())
        .fontSize(this.fontSize)
        .fontColor(this.textColor)
        .lineHeight(this.lineHeight)
        .width('100%')
        .textAlign(TextAlign.Start)
    } else if (!this.renderReady) {
      Text(this.plainFallbackText())
        .fontSize(this.fontSize)
        .fontColor(this.textColor)
        .lineHeight(this.lineHeight)
        .width('100%')
        .textAlign(TextAlign.Start)
    } else {
      Web({ src: $rawfile('render.html'), controller: this.controller })
        .javaScriptAccess(true)
        .domStorageAccess(false)
        .fileAccess(false)
        .horizontalScrollBarAccess(true)
        .verticalScrollBarAccess(false)
        .backgroundColor('rgba(0,0,0,0)')
        .width('100%')
        .height(this.webHeight)
        .onPageEnd((): void => {
          this.pageReady = true
          this.renderContent()
        })
    }
  }
}

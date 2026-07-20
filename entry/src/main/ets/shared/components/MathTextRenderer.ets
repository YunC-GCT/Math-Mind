// ============================================================================
//  shared/components/MathTextRenderer.ets - KaTeX Web renderer wrapper
// ============================================================================

import {
  TEXT, TEXT_2, GLASS_10, BORDER,
  F_BASE,
} from 'common'
import webview from '@ohos.web.webview'

class MathRenderCacheEntry {
  key: string = ''
  encodedHtml: string = ''
  height: number = 0
  touched: number = 0

  constructor(key: string, encodedHtml: string, height: number, touched: number) {
    this.key = key
    this.encodedHtml = encodedHtml
    this.height = height
    this.touched = touched
  }
}

class MathRenderPayload {
  height: number = 0
  encodedHtml: string = ''
}

const MATH_RENDER_CACHE: MathRenderCacheEntry[] = []
const MATH_RENDER_CACHE_LIMIT: number = 96
let mathRenderCacheClock: number = 0

function nextCacheTick(): number {
  mathRenderCacheClock += 1
  return mathRenderCacheClock
}

function cacheGet(key: string): MathRenderCacheEntry | null {
  for (const entry of MATH_RENDER_CACHE) {
    if (entry.key === key) {
      entry.touched = nextCacheTick()
      return entry
    }
  }
  return null
}

function cacheSet(key: string, encodedHtml: string, height: number): void {
  const touched: number = nextCacheTick()
  for (const entry of MATH_RENDER_CACHE) {
    if (entry.key === key) {
      entry.encodedHtml = encodedHtml
      entry.height = height
      entry.touched = touched
      return
    }
  }
  MATH_RENDER_CACHE.push(new MathRenderCacheEntry(key, encodedHtml, height, touched))
  trimCache()
}

function trimCache(): void {
  while (MATH_RENDER_CACHE.length > MATH_RENDER_CACHE_LIMIT) {
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
  @State private pageReady: boolean = false
  @State private webHeight: number = 42

  aboutToAppear(): void {
    const markdown: string = this.prepareMarkdown(this.text)
    const cached: MathRenderCacheEntry | null = cacheGet(this.cacheKey(markdown))
    if (cached !== null) {
      this.webHeight = this.clampHeight(cached.height)
      return
    }
    this.webHeight = this.estimateHeight(markdown)
  }

  onTextChanged(): void {
    if (this.pageReady) {
      this.renderContent()
    }
  }

  private renderContent = (): void => {
    const markdown: string = this.prepareMarkdown(this.text)
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
    return this.cacheKey(this.prepareMarkdown(this.text))
  }

  private clampHeight = (height: number): number => {
    return Math.max(this.minHeight, Math.min(this.maxHeight, height))
  }

  private prepareMarkdown = (raw: string): string => {
    const normalized: string = raw.replace(/\r\n/g, '\n').trim()
    if (normalized.length === 0) {
      return ''
    }
    if (this.forceDisplay) {
      return '$$\n' + this.stripDisplayFence(normalized) + '\n$$'
    }
    return this.wrapFormulaOnlyLines(normalized)
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
    return (line.indexOf('，') < 0
      && line.indexOf('。') < 0
      && line.indexOf('；') < 0
      && line.indexOf('：') < 0
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
      + (this.forceDisplay ? 1 : 0)
    const formulaExtra: number = displayFormulaCount * (this.profile === 'note' ? 42 : 34)
    const estimated: number = lineCount * baseLineHeight + formulaExtra + 18
    return this.clampHeight(estimated)
  }

  build() {
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

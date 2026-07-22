/**
 * MathTextParser.ets — MM-MD-v1 数学文本兼容分块器
 *
 * 路径: utils/MathTextParser.ets
 * 职责: 将已通过 ContentProtocol 的文本拆成普通文本和公式块
 * 依赖: common/ContentProtocol
 *
 * 数据流:
 *   原始文本 -> ContentProtocol -> splitMathText -> TextBlock[]
 *
 * ArkTS 1.1 strict 适配:
 *   - 不猜测裸公式，不使用 C 风格 for
 */

import { ContentProtocol } from 'common'
import type { ContentValidationResult } from 'common'

export interface TextBlock {
  kind: 'text' | 'formula'
  content: string
}

function pushTextBlock(blocks: TextBlock[], lines: string[]): void {
  const content: string = lines.join('\n').trim()
  if (content.length > 0) {
    blocks.push({ kind: 'text', content: content })
  }
  lines.splice(0, lines.length)
}

function pushFormulaBlock(blocks: TextBlock[], lines: string[]): void {
  const content: string = lines.join('\n').trim()
  if (content.length > 0) {
    blocks.push({ kind: 'formula', content: content })
  }
  lines.splice(0, lines.length)
}

function isEscapedAt(text: string, index: number): boolean {
  let slashCount: number = 0
  let slashIndex: number = index - 1
  while (slashIndex >= 0 && text.charAt(slashIndex) === '\\') {
    slashCount += 1
    slashIndex -= 1
  }
  return slashCount % 2 !== 0
}

function nextUnescapedDollar(text: string, start: number): number {
  let index: number = text.indexOf('$', start)
  while (index >= 0) {
    if (!isEscapedAt(text, index)) {
      return index
    }
    index = text.indexOf('$', index + 1)
  }
  return -1
}

function pushInlineBlocks(blocks: TextBlock[], line: string): void {
  let cursor: number = 0
  let openIndex: number = nextUnescapedDollar(line, cursor)
  while (openIndex >= 0) {
    const closeIndex: number = nextUnescapedDollar(line, openIndex + 1)
    if (closeIndex < 0) {
      blocks.push({ kind: 'text', content: line.substring(cursor) })
      return
    }
    const prefix: string = line.substring(cursor, openIndex).trim()
    const formula: string = line.substring(openIndex + 1, closeIndex).trim()
    if (prefix.length > 0) {
      blocks.push({ kind: 'text', content: prefix })
    }
    if (formula.length > 0) {
      blocks.push({ kind: 'formula', content: formula })
    }
    cursor = closeIndex + 1
    openIndex = nextUnescapedDollar(line, cursor)
  }
  const suffix: string = line.substring(cursor).trim()
  if (suffix.length > 0) {
    blocks.push({ kind: 'text', content: suffix })
  }
}

export function splitMathText(text: string): TextBlock[] {
  const protocolResult: ContentValidationResult = new ContentProtocol().normalizeNoteMarkdown(text)
  const normalized: string = protocolResult.normalizedText
  if (normalized.length === 0) {
    return []
  }
  if (protocolResult.fallbackRequired) {
    return [{ kind: 'text', content: normalized }]
  }

  const blocks: TextBlock[] = []
  const textLines: string[] = []
  const formulaLines: string[] = []
  let inCode: boolean = false
  let inFormula: boolean = false
  for (const rawLine of normalized.split('\n')) {
    const trimmed: string = rawLine.trim()
    if (trimmed.indexOf('```') === 0) {
      inCode = !inCode
      textLines.push(rawLine)
      continue
    }
    if (inCode) {
      textLines.push(rawLine)
      continue
    }
    if (inFormula) {
      if (trimmed === '$$') {
        pushFormulaBlock(blocks, formulaLines)
        inFormula = false
      } else {
        formulaLines.push(rawLine)
      }
      continue
    }
    if (trimmed === '$$') {
      pushTextBlock(blocks, textLines)
      inFormula = true
      continue
    }
    if (trimmed.length === 0) {
      pushTextBlock(blocks, textLines)
      continue
    }
    if (nextUnescapedDollar(rawLine, 0) >= 0) {
      pushTextBlock(blocks, textLines)
      pushInlineBlocks(blocks, rawLine)
      continue
    }
    textLines.push(rawLine)
  }
  pushTextBlock(blocks, textLines)
  if (blocks.length === 0) {
    blocks.push({ kind: 'text', content: normalized })
  }
  return blocks
}

// ============================================================================
//  utils/MarkdownParser.ets - lightweight markdown block parser
// ============================================================================

export interface MarkdownBlock {
  kind: string
  text: string
  level: number
  items: string[]
  ordered: boolean
  lang: string
}

function emptyBlock(kind: string): MarkdownBlock {
  return {
    kind: kind,
    text: '',
    level: 0,
    items: [],
    ordered: false,
    lang: '',
  }
}

function pushParagraph(blocks: MarkdownBlock[], lines: string[]): void {
  const text: string = lines.join('\n').trim()
  if (text.length > 0) {
    const block: MarkdownBlock = emptyBlock('paragraph')
    block.text = text
    blocks.push(block)
  }
  lines.splice(0, lines.length)
}

function pushQuote(blocks: MarkdownBlock[], lines: string[]): void {
  const text: string = lines.join('\n').trim()
  if (text.length > 0) {
    const block: MarkdownBlock = emptyBlock('quote')
    block.text = text
    blocks.push(block)
  }
  lines.splice(0, lines.length)
}

function pushList(blocks: MarkdownBlock[], items: string[], ordered: boolean): void {
  if (items.length > 0) {
    const block: MarkdownBlock = emptyBlock('list')
    block.items = items.slice()
    block.ordered = ordered
    blocks.push(block)
  }
  items.splice(0, items.length)
}

function pushCode(blocks: MarkdownBlock[], lines: string[], lang: string): void {
  const block: MarkdownBlock = emptyBlock('code')
  block.text = lines.join('\n')
  block.lang = lang
  blocks.push(block)
  lines.splice(0, lines.length)
}

function headingLevel(line: string): number {
  let count: number = 0
  while (count < line.length && line.charAt(count) === '#') {
    count += 1
  }
  if (count < 1 || count > 3 || line.charAt(count) !== ' ') {
    return 0
  }
  return count
}

function unorderedItemText(line: string): string {
  if (line.length > 2) {
    const marker: string = line.charAt(0)
    if ((marker === '-' || marker === '*' || marker === '+') && line.charAt(1) === ' ') {
      return line.substring(2).trim()
    }
  }
  return ''
}

function orderedItemText(line: string): string {
  let index: number = 0
  while (index < line.length && line.charAt(index) >= '0' && line.charAt(index) <= '9') {
    index += 1
  }
  if (index > 0 && index + 1 < line.length && line.charAt(index) === '.' && line.charAt(index + 1) === ' ') {
    return line.substring(index + 2).trim()
  }
  return ''
}

function isRule(line: string): boolean {
  return line === '---' || line === '***' || line === '___'
}

function isFormulaFence(line: string): boolean {
  return line === '$$' || line === '\\['
}

function isFormulaClose(line: string, fence: string): boolean {
  return fence === '$$' && line === '$$' || fence === '\\[' && line === '\\]'
}

function flushOpenBlocks(
  blocks: MarkdownBlock[],
  paragraphLines: string[],
  quoteLines: string[],
  listItems: string[],
  listOrdered: boolean,
): void {
  pushParagraph(blocks, paragraphLines)
  pushQuote(blocks, quoteLines)
  pushList(blocks, listItems, listOrdered)
}

export function parseMarkdown(text: string): MarkdownBlock[] {
  const normalized: string = text.replace(/\r\n/g, '\n').replace(/\r/g, '\n').trim()
  if (normalized.length === 0) {
    return []
  }

  const blocks: MarkdownBlock[] = []
  const lines: string[] = normalized.split('\n')
  const paragraphLines: string[] = []
  const quoteLines: string[] = []
  const listItems: string[] = []
  const codeLines: string[] = []
  const formulaLines: string[] = []
  let listOrdered: boolean = false
  let inCode: boolean = false
  let inFormula: boolean = false
  let codeLang: string = ''
  let formulaFence: string = ''

  for (const rawLine of lines) {
    const line: string = rawLine
    const trimmed: string = rawLine.trim()

    if (inCode) {
      if (trimmed.indexOf('```') === 0) {
        pushCode(blocks, codeLines, codeLang)
        inCode = false
        codeLang = ''
      } else {
        codeLines.push(line)
      }
      continue
    }

    if (inFormula) {
      if (isFormulaClose(trimmed, formulaFence)) {
        const block: MarkdownBlock = emptyBlock('formula')
        block.text = formulaLines.join('\n').trim()
        blocks.push(block)
        formulaLines.splice(0, formulaLines.length)
        inFormula = false
        formulaFence = ''
      } else {
        formulaLines.push(line)
      }
      continue
    }

    if (trimmed.length === 0) {
      flushOpenBlocks(blocks, paragraphLines, quoteLines, listItems, listOrdered)
      continue
    }

    if (trimmed.indexOf('```') === 0) {
      flushOpenBlocks(blocks, paragraphLines, quoteLines, listItems, listOrdered)
      inCode = true
      codeLang = trimmed.length > 3 ? trimmed.substring(3).trim() : ''
      continue
    }

    if (isFormulaFence(trimmed)) {
      flushOpenBlocks(blocks, paragraphLines, quoteLines, listItems, listOrdered)
      inFormula = true
      formulaFence = trimmed
      continue
    }

    if (isRule(trimmed)) {
      flushOpenBlocks(blocks, paragraphLines, quoteLines, listItems, listOrdered)
      blocks.push(emptyBlock('rule'))
      continue
    }

    const level: number = headingLevel(trimmed)
    if (level > 0) {
      flushOpenBlocks(blocks, paragraphLines, quoteLines, listItems, listOrdered)
      const block: MarkdownBlock = emptyBlock('heading')
      block.level = level
      block.text = trimmed.substring(level + 1).trim()
      blocks.push(block)
      continue
    }

    if (trimmed.indexOf('> ') === 0) {
      pushParagraph(blocks, paragraphLines)
      pushList(blocks, listItems, listOrdered)
      quoteLines.push(trimmed.substring(2).trim())
      continue
    }

    const unorderedText: string = unorderedItemText(trimmed)
    if (unorderedText.length > 0) {
      pushParagraph(blocks, paragraphLines)
      pushQuote(blocks, quoteLines)
      if (listItems.length > 0 && listOrdered) {
        pushList(blocks, listItems, listOrdered)
      }
      listOrdered = false
      listItems.push(unorderedText)
      continue
    }

    const orderedText: string = orderedItemText(trimmed)
    if (orderedText.length > 0) {
      pushParagraph(blocks, paragraphLines)
      pushQuote(blocks, quoteLines)
      if (listItems.length > 0 && !listOrdered) {
        pushList(blocks, listItems, listOrdered)
      }
      listOrdered = true
      listItems.push(orderedText)
      continue
    }

    pushQuote(blocks, quoteLines)
    pushList(blocks, listItems, listOrdered)
    paragraphLines.push(line)
  }

  if (inCode) {
    pushCode(blocks, codeLines, codeLang)
  }
  if (inFormula) {
    const block: MarkdownBlock = emptyBlock('formula')
    block.text = formulaLines.join('\n').trim()
    blocks.push(block)
  }
  flushOpenBlocks(blocks, paragraphLines, quoteLines, listItems, listOrdered)

  return blocks
}

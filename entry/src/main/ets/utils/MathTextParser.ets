// ============================================================================
//  utils/MathTextParser.ets - parse plain text and LaTeX-style formula blocks
// ============================================================================

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

function looksLikeFormulaLine(text: string): boolean {
  if (text.length === 0 || text.indexOf('LaTeX formulas:') === 0) {
    return false
  }
  if (
    text.indexOf('\\frac') >= 0 ||
    text.indexOf('\\sqrt') >= 0 ||
    text.indexOf('\\sum') >= 0 ||
    text.indexOf('\\int') >= 0 ||
    text.indexOf('\\lim') >= 0 ||
    text.indexOf('\\begin') >= 0 ||
    text.indexOf('\\alpha') >= 0 ||
    text.indexOf('\\beta') >= 0
  ) {
    return true
  }
  if (text.indexOf('=') >= 0 && (text.indexOf('^') >= 0 || text.indexOf('_') >= 0 || text.indexOf('\\') >= 0)) {
    return true
  }
  return false
}

export function splitMathText(text: string): TextBlock[] {
  const normalized: string = text.replace(/\r\n/g, '\n').trim()
  if (normalized.length === 0) {
    return []
  }

  const blocks: TextBlock[] = []
  const lines: string[] = normalized.split('\n')
  let textLines: string[] = []
  let formulaLines: string[] = []
  let inFormula: boolean = false
  let fence: string = ''

  for (const rawLine of lines) {
    const line: string = rawLine
    const trimmed: string = rawLine.trim()

    if (inFormula) {
      const isClosingFence: boolean = fence === '$$' && trimmed === '$$'
        || fence === '\\[' && trimmed === '\\]'
        || fence === '\\(' && trimmed === '\\)'

      if (isClosingFence) {
        pushFormulaBlock(blocks, formulaLines)
        inFormula = false
        fence = ''
      } else {
        formulaLines.push(line)
      }
      continue
    }

    if (trimmed.length === 0) {
      pushTextBlock(blocks, textLines)
      continue
    }

    if (trimmed.startsWith('$$') && trimmed.endsWith('$$') && trimmed.length > 4) {
      pushTextBlock(blocks, textLines)
      blocks.push({ kind: 'formula', content: trimmed.substring(2, trimmed.length - 2).trim() })
      continue
    }

    if (trimmed === '$$') {
      pushTextBlock(blocks, textLines)
      inFormula = true
      fence = '$$'
      continue
    }

    if (trimmed.startsWith('\\[') && trimmed.endsWith('\\]') && trimmed.length > 4) {
      pushTextBlock(blocks, textLines)
      blocks.push({ kind: 'formula', content: trimmed.substring(2, trimmed.length - 2).trim() })
      continue
    }

    if (trimmed === '\\[') {
      pushTextBlock(blocks, textLines)
      inFormula = true
      fence = '\\['
      continue
    }

    if (trimmed.startsWith('\\(') && trimmed.endsWith('\\)') && trimmed.length > 4) {
      pushTextBlock(blocks, textLines)
      blocks.push({ kind: 'formula', content: trimmed.substring(2, trimmed.length - 2).trim() })
      continue
    }

    if (trimmed === '\\(') {
      pushTextBlock(blocks, textLines)
      inFormula = true
      fence = '\\('
      continue
    }

    if (looksLikeFormulaLine(trimmed)) {
      pushTextBlock(blocks, textLines)
      blocks.push({ kind: 'formula', content: trimmed })
      continue
    }

    textLines.push(line)
  }

  if (inFormula) {
    pushFormulaBlock(blocks, formulaLines)
  } else {
    pushTextBlock(blocks, textLines)
  }

  if (blocks.length === 0) {
    blocks.push({ kind: 'text', content: normalized })
  }
  return blocks
}

// ============================================================================
//  utils/MarkdownInlineParser.ets - tiny inline markdown parser
// ============================================================================

export interface MarkdownInlineSegment {
  kind: string
  text: string
}

function pushSegment(segments: MarkdownInlineSegment[], kind: string, text: string): void {
  if (text.length > 0) {
    segments.push({ kind: kind, text: text })
  }
}

export function parseMarkdownInline(text: string): MarkdownInlineSegment[] {
  const segments: MarkdownInlineSegment[] = []
  let index: number = 0
  let buffer: string = ''

  while (index < text.length) {
    const rest: string = text.substring(index)

    if (rest.indexOf('**') === 0) {
      const close: number = text.indexOf('**', index + 2)
      if (close > index + 2) {
        pushSegment(segments, 'text', buffer)
        buffer = ''
        pushSegment(segments, 'bold', text.substring(index + 2, close))
        index = close + 2
        continue
      }
    }

    if (rest.indexOf('`') === 0) {
      const closeCode: number = text.indexOf('`', index + 1)
      if (closeCode > index + 1) {
        pushSegment(segments, 'text', buffer)
        buffer = ''
        pushSegment(segments, 'code', text.substring(index + 1, closeCode))
        index = closeCode + 1
        continue
      }
    }

    buffer += text.charAt(index)
    index += 1
  }

  pushSegment(segments, 'text', buffer)
  if (segments.length === 0) {
    pushSegment(segments, 'text', text)
  }
  return segments
}

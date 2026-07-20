// ============================================================================
//  shared/components/MarkdownRenderer.ets - lightweight native markdown renderer
// ============================================================================

import {
  MINT,
  BG_CARD,
  TEXT,
  TEXT_2,
  TEXT_3,
  BORDER,
  GLASS_10,
  S_1, S_2, S_3,
  R_MD,
  F_SM, F_BASE, F_MD, F_LG,
  W_MEDIUM, W_SEMIBOLD, W_BOLD,
} from 'common'
import { parseMarkdown, MarkdownBlock } from '../../utils/MarkdownParser'
import { parseMarkdownInline, MarkdownInlineSegment } from '../../utils/MarkdownInlineParser'
import { MathTextRenderer } from './MathTextRenderer'

@Component
export struct MarkdownRenderer {
  @Prop text: string = ''

  build() {
    if (this.containsFormulaSyntax(this.text)) {
      MathTextRenderer({
        text: this.text,
        profile: 'note',
        textColor: TEXT_2,
        formulaColor: TEXT_2,
        formulaBackground: 'rgba(255,255,255,0.04)',
        formulaBorder: 'rgba(255,255,255,0.10)',
        fontSize: F_BASE,
        lineHeight: 26,
        formulaFontSize: F_BASE,
        formulaLineHeight: 26,
      })
    } else {
      Column() {
        ForEach(parseMarkdown(this.text),
          (block: MarkdownBlock, index: number): void => {
            if (block.kind === 'heading') {
              this.Heading(block)
            } else if (block.kind === 'list') {
              this.ListBlock(block)
            } else if (block.kind === 'quote') {
              this.QuoteBlock(block)
            } else if (block.kind === 'code') {
              this.CodeBlock(block)
            } else if (block.kind === 'formula') {
              this.FormulaBlock(block)
            } else if (block.kind === 'rule') {
              this.RuleBlock()
            } else {
              this.Paragraph(block.text)
            }
          },
          (_block: MarkdownBlock, index: number): string => index.toString()
        )
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }

  @Builder
  Heading(block: MarkdownBlock) {
    Text(block.text)
      .fontSize(this.headingSize(block.level))
      .fontWeight(W_BOLD)
      .fontColor(block.level === 1 ? TEXT : MINT)
      .lineHeight(this.headingLineHeight(block.level))
      .width('100%')
      .margin({ top: block.level === 1 ? S_3 : S_2, bottom: S_2 })
  }

  @Builder
  Paragraph(text: string) {
    if (this.containsFormulaSyntax(text)) {
      MathTextRenderer({
        text: text,
        profile: 'note',
        textColor: TEXT_2,
        formulaColor: TEXT_2,
        formulaBackground: 'rgba(255,255,255,0.04)',
        formulaBorder: 'rgba(255,255,255,0.10)',
        fontSize: F_BASE,
        lineHeight: 26,
        formulaFontSize: F_BASE,
        formulaLineHeight: 26,
      })
    } else {
      Text() {
        ForEach(parseMarkdownInline(text),
          (segment: MarkdownInlineSegment, index: number): void => {
            Span(segment.text)
              .fontSize(F_BASE)
              .fontColor(segment.kind === 'code' ? TEXT : TEXT_2)
              .fontWeight(segment.kind === 'bold' ? W_BOLD : W_MEDIUM)
              .fontFamily(segment.kind === 'code' ? 'monospace' : '')
          },
          (_segment: MarkdownInlineSegment, index: number): string => index.toString()
        )
      }
      .fontSize(F_BASE)
      .fontColor(TEXT_2)
      .lineHeight(26)
      .width('100%')
      .textAlign(TextAlign.Start)
      .margin({ bottom: S_2 })
    }
  }

  @Builder
  ListBlock(block: MarkdownBlock) {
    Column() {
      ForEach(block.items,
        (item: string, index: number): void => {
          Row() {
            Text(block.ordered ? (index + 1).toString() + '.' : '•')
              .fontSize(F_BASE)
              .fontColor(MINT)
              .fontWeight(W_SEMIBOLD)
              .width(24)
              .textAlign(TextAlign.Start)

            Column() {
              this.Paragraph(item)
            }
            .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        },
        (item: string, index: number): string => index.toString() + item
      )
    }
    .width('100%')
    .margin({ top: S_1, bottom: S_1 })
  }

  @Builder
  QuoteBlock(block: MarkdownBlock) {
    Row() {
      Column()
        .width(3)
        .height('100%')
        .backgroundColor(MINT)
        .borderRadius(2)
        .margin({ right: S_2 })

      Column() {
        this.Paragraph(block.text)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: S_2, right: S_2, top: S_2, bottom: S_2 })
    .margin({ top: S_1, bottom: S_2 })
    .borderRadius(R_MD)
    .backgroundColor(GLASS_10)
  }

  @Builder
  CodeBlock(block: MarkdownBlock) {
    Column() {
      if (block.lang.length > 0) {
        Text(block.lang)
          .fontSize(F_SM)
          .fontColor(TEXT_3)
          .fontWeight(W_SEMIBOLD)
          .width('100%')
          .margin({ bottom: S_1 })
      }

      Text(block.text)
        .fontSize(F_SM)
        .fontColor(TEXT)
        .fontFamily('monospace')
        .lineHeight(22)
        .width('100%')
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
    .margin({ top: S_1, bottom: S_2 })
    .borderRadius(R_MD)
    .backgroundColor(BG_CARD)
    .border({ width: 1, color: BORDER })
  }

  @Builder
  FormulaBlock(block: MarkdownBlock) {
    MathTextRenderer({
      text: block.text,
      profile: 'note',
      forceDisplay: true,
      textColor: TEXT_2,
      formulaColor: TEXT_2,
      formulaBackground: 'rgba(255,255,255,0.04)',
      formulaBorder: 'rgba(255,255,255,0.10)',
      fontSize: F_BASE,
      lineHeight: 26,
      formulaFontSize: F_BASE,
      formulaLineHeight: 26,
    })
  }

  @Builder
  RuleBlock() {
    Divider()
      .strokeWidth(1)
      .color(BORDER)
      .width('100%')
      .margin({ top: S_3, bottom: S_3 })
  }

  private headingSize(level: number): number {
    if (level === 1) { return F_LG }
    if (level === 2) { return F_MD }
    return F_SM
  }

  private headingLineHeight(level: number): number {
    if (level === 1) { return 28 }
    if (level === 2) { return 24 }
    return 20
  }

  private containsFormulaSyntax(text: string): boolean {
    return text.indexOf('$$') >= 0
      || text.indexOf('$') >= 0
      || text.indexOf('\\[') >= 0
      || text.indexOf('\\(') >= 0
      || text.indexOf('\\') >= 0
      || text.indexOf('\\frac') >= 0
      || text.indexOf('\\sqrt') >= 0
      || text.indexOf('\\sum') >= 0
      || text.indexOf('\\int') >= 0
      || text.indexOf('\\lim') >= 0
      || text.indexOf('\\begin') >= 0
      || text.indexOf('=') >= 0 && (text.indexOf('^') >= 0 || text.indexOf('_') >= 0 || text.indexOf('\\') >= 0)
  }
}

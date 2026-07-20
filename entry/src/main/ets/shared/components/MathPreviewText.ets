// ============================================================================
// shared/components/MathPreviewText.ets - compact note preview with KaTeX fallback
// ============================================================================

import { TEXT_3, F_SM } from 'common'
import { MathTextRenderer } from './MathTextRenderer'

@Component
export struct MathPreviewText {
  @Prop text: string = ''
  @Prop textColor: ResourceColor = TEXT_3
  @Prop fontSize: number = F_SM
  @Prop lineHeightValue: number = 18
  @Prop maxLines: number = 2
  @Prop minHeight: number = 34
  @Prop maxHeight: number = 44

  private containsFormulaSyntax = (text: string): boolean => {
    return text.indexOf('$') >= 0
      || text.indexOf('\\[') >= 0
      || text.indexOf('\\]') >= 0
      || text.indexOf('\\(') >= 0
      || text.indexOf('\\)') >= 0
      || text.indexOf('\\') >= 0
      || text.indexOf('\\frac') >= 0
      || text.indexOf('\\sqrt') >= 0
      || text.indexOf('\\sum') >= 0
      || text.indexOf('\\int') >= 0
      || text.indexOf('\\lim') >= 0
      || text.indexOf('\\begin') >= 0
      || text.indexOf('\\mu') >= 0
      || text.indexOf('\\sigma') >= 0
      || text.indexOf('\\alpha') >= 0
      || text.indexOf('\\beta') >= 0
      || text.indexOf('\\theta') >= 0
      || (text.indexOf('^') >= 0 && text.indexOf('=') >= 0)
      || (text.indexOf('_') >= 0 && text.indexOf('=') >= 0)
  }

  build() {
    if (this.containsFormulaSyntax(this.text)) {
      MathTextRenderer({
        text: this.text,
        profile: 'preview',
        textColor: this.textColor,
        formulaColor: this.textColor,
        fontSize: this.fontSize,
        lineHeight: this.lineHeightValue,
        formulaFontSize: this.fontSize,
        formulaLineHeight: this.lineHeightValue,
        minHeight: this.minHeight,
        maxHeight: this.maxHeight,
      })
    } else {
      Text(this.text)
        .fontSize(this.fontSize)
        .fontColor(this.textColor)
        .lineHeight(this.lineHeightValue)
        .maxLines(this.maxLines)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
  }
}

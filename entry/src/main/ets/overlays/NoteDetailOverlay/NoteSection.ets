// ============================================================================
//  overlays/NoteDetailOverlay/NoteSection.ets - note section renderer
// ============================================================================

import { MINT, TEXT_2, S_2, S_3, F_SM, F_BASE, W_BOLD } from 'common'
import { MathTextRenderer } from '../../shared/components/MathTextRenderer'

@Component
export struct NoteSectionView {
  @Prop title: string = ''
  @Prop content: string = ''

  build() {
    Column() {
      if (this.title.trim().length > 0) {
        Text(this.title)
          .fontSize(F_SM)
          .fontWeight(W_BOLD)
          .fontColor(MINT)
          .letterSpacing(0)
          .width('100%')
          .margin({ top: S_3, bottom: S_2 })
      }

      if (this.content.trim().length > 0) {
        MathTextRenderer({
          text: this.content,
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
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

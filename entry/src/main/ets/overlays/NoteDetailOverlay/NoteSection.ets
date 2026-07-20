// ============================================================================
//  overlays/NoteDetailOverlay/NoteSection.ets - note section renderer
// ============================================================================

import { MINT, S_2, S_3, F_SM, W_BOLD } from 'common'
import { MarkdownRenderer } from '../../shared/components/MarkdownRenderer'

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
        MarkdownRenderer({ text: this.content })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

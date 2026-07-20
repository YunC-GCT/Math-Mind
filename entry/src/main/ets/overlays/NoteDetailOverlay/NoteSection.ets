// ============================================================================
//  overlays/NoteDetailOverlay/NoteSection.ets - note section renderer
// ============================================================================

import { MINT, TEXT_2, BORDER, S_2, S_3, S_4, F_SM, W_BOLD } from 'common'
import { MarkdownRenderer } from '../../shared/components/MarkdownRenderer'

@Component
export struct NoteSectionView {
  @Prop title: string = ''
  @Prop content: string = ''

  build() {
    Column() {
      if (this.title.trim().length > 0) {
        Row() {
          Column()
            .width(3)
            .height(16)
            .borderRadius(2)
            .backgroundColor(MINT)
            .margin({ right: S_2 })

          Text(this.title)
            .fontSize(F_SM)
            .fontWeight(W_BOLD)
            .fontColor(TEXT_2)
            .letterSpacing(0)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ top: S_4, bottom: S_2 })
      }

      if (this.content.trim().length > 0) {
        MarkdownRenderer({ text: this.content })
      }
    }
    .width('100%')
    .padding({ bottom: S_3 })
    .border({ width: { bottom: 0.5 }, color: BORDER })
    .alignItems(HorizontalAlign.Start)
  }
}

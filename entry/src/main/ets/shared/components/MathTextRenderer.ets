// ============================================================================
//  shared/components/MathTextRenderer.ets - text + formula block renderer
// ============================================================================

import {
  TEXT, TEXT_2, BORDER, GLASS_10,
  S_1, S_2, S_3,
  R_MD,
  F_BASE,
  W_MEDIUM,
} from 'common'
import { splitMathText, TextBlock as MathTextBlock } from '../../utils/MathTextParser'

@Component
export struct MathTextRenderer {
  @Prop text: string = ''
  @Prop textColor: ResourceColor = TEXT_2
  @Prop formulaColor: ResourceColor = TEXT
  @Prop formulaBackground: ResourceColor = GLASS_10
  @Prop formulaBorder: ResourceColor = BORDER
  @Prop fontSize: number = F_BASE
  @Prop lineHeight: number = 24
  @Prop formulaFontSize: number = F_BASE
  @Prop formulaLineHeight: number = 24

  build() {
    Column() {
      ForEach(splitMathText(this.text),
        (block: MathTextBlock, _index: number): void => {
          if (block.kind === 'formula') {
            Column() {
              Text(block.content)
                .fontSize(this.formulaFontSize)
                .fontColor(this.formulaColor)
                .fontWeight(W_MEDIUM)
                .lineHeight(this.formulaLineHeight)
                .width('100%')
                .textAlign(TextAlign.Start)
            }
            .width('100%')
            .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
            .margin({ top: S_1, bottom: S_1 })
            .borderRadius(R_MD)
            .backgroundColor(this.formulaBackground)
            .border({ width: 1, color: this.formulaBorder })
          } else {
            Text(block.content)
              .fontSize(this.fontSize)
              .fontColor(this.textColor)
              .lineHeight(this.lineHeight)
              .width('100%')
              .textAlign(TextAlign.Start)
          }
        },
        (_block: MathTextBlock, index: number): string => index.toString()
      )
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

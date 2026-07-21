/**
 * DetailStepsSection.ets — 带标题的步骤型详情分块
 *
 * 路径: entry/src/main/ets/overlays/NoteDetailOverlay/components/DetailStepsSection.ets
 * 职责: 为证明过程、计算步骤提供阅读型编号分块。
 * 依赖: common tokens, DetailStepList
 *
 * 数据流:
 *   renderer → DetailStepsSection → DetailStepList
 *
 * ArkTS 1.1 strict 适配:
 *   - struct 内无普通方法
 */

import {
  MINT, TEXT, TEXT_2, BORDER,
  S_2, S_3, S_4,
  F_SM,
  W_BOLD,
} from 'common'
import { DetailStepList } from './DetailStepList'

@Component
export struct DetailStepsSection {
  @Prop title: string = ''
  @Prop items: string[] = []
  @Prop accentColor: ResourceColor = MINT
  @Prop emphasized: boolean = false

  build() {
    if (this.items.length > 0) {
      Column() {
        Row() {
          Column()
            .width(3)
            .height(16)
            .borderRadius(2)
            .backgroundColor(this.accentColor)
            .margin({ right: S_2 })

          Text(this.title)
            .fontSize(F_SM)
            .fontWeight(W_BOLD)
            .fontColor(this.emphasized ? TEXT : TEXT_2)
            .letterSpacing(0)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: S_2 })

        DetailStepList({ items: this.items, accentColor: this.accentColor })
      }
      .width('100%')
      .padding({ top: S_4, bottom: S_3 })
      .border({ width: { bottom: 0.5 }, color: BORDER })
      .alignItems(HorizontalAlign.Start)
    }
  }
}

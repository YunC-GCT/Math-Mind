/**
 * DetailSection.ets — 阅读型详情页主分块
 *
 * 路径: entry/src/main/ets/overlays/NoteDetailOverlay/components/DetailSection.ets
 * 职责: 提供唯一明显正文分块，内部交给 MarkdownRenderer 渲染内容。
 * 依赖: common tokens, MarkdownRenderer
 *
 * 数据流:
 *   renderer → DetailSection → MarkdownRenderer
 *
 * ArkTS 1.1 strict 适配:
 *   - struct 内无普通方法
 *   - 字段名避开 CommonAttribute 方法
 */

import {
  MINT, TEXT, TEXT_2, BORDER,
  S_2, S_3, S_4,
  F_SM,
  W_BOLD,
} from 'common'
import { MarkdownRenderer } from '../../../shared/components/MarkdownRenderer'

@Component
export struct DetailSection {
  @Prop title: string = ''
  @Prop content: string = ''
  @Prop accentColor: ResourceColor = MINT
  @Prop emphasized: boolean = false

  build() {
    if (this.content.trim().length > 0) {
      Column() {
        if (this.title.trim().length > 0) {
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
        }

        MarkdownRenderer({ text: this.content })
      }
      .width('100%')
      .padding({ top: S_4, bottom: S_3 })
      .border({ width: { bottom: 0.5 }, color: BORDER })
      .alignItems(HorizontalAlign.Start)
    }
  }
}

// ============================================================================
//  pages/AiSettings/SectionHeader.ets — 设置页分组标题
//  ----------------------------------------------------------------------------
//  职责: 设置页每个分组的小标题(主标题 + 副描述)。
//
//  依赖: common 令牌(TEXT / TEXT_4 / F_XS / F_SM / W_SEMIBOLD / S_2)
//
//  Props:
//    title: 主标题(如 "服务端点")
//    desc:  副描述(可空,空时只显示主标题)
//  ============================================================================

import { TEXT, TEXT_4, F_XS, F_SM, W_SEMIBOLD, S_2 } from "common"

@Component
export struct SectionHeader {
  // 主标题
  @Prop title: string = ""

  // 副描述(可空)
  @Prop desc: string = ""

  build() {
    Column() {
      Text(this.title)
        .fontSize(F_SM)
        .fontWeight(W_SEMIBOLD)
        .fontColor(TEXT)

      // 副描述(只在非空时显示)
      if (this.desc) {
        Text(this.desc)
          .fontSize(F_XS)
          .fontColor(TEXT_4)
          .margin({ top: 2 })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width("100%")
    .padding({ left: 20, right: S_2, top: 20, bottom: 8 })
  }
}

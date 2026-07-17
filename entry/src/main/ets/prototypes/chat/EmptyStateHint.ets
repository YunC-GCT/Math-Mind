// ============================================================================
//  prototypes/chat/EmptyStateHint.ets — 空状态引导
//  ----------------------------------------------------------------------------
//  职责: 无消息时显示品牌钻石 SVG + 引导文案。
//
//  UI:
//        [◆ 钻石 SVG(双层 MINT 渐变)]
//     "有什么数学问题?"
//    "试试下方的推荐问题,或直接输入"
//
//  依赖: common ColorTokens (MINT/TEXT/TEXT_3)
//
//  来源: 从 AgentFloatWindow 内联代码拆出
//  ============================================================================

import { MINT, TEXT, TEXT_3, S_2, S_3, S_6, F_XS, F_MD, W_SEMIBOLD } from "common"

@Component
export struct EmptyStateHint {
  build() {
    Column() {
      // 双层钻石 SVG
      Stack() {
        // 外层大钻石(浅)
        Path()
          .width(30).height(30)
          .commands("M 15 0 L 28 15 L 15 30 L 2 15 Z")
          .fill(MINT)
          .opacity(0.3)
        // 内层小钻石(深)
        Path()
          .width(18).height(18)
          .commands("M 15 4 L 26 15 L 15 26 L 4 15 Z")
          .fill(MINT)
      }
      .width(48).height(48)
      .margin({ bottom: S_3 })

      // 主标题
      Text("有什么数学问题?")
        .fontSize(F_MD)
        .fontWeight(W_SEMIBOLD)
        .fontColor(TEXT)

      // 副提示
      Text("试试下方的推荐问题,或直接输入")
        .fontSize(F_XS)
        .fontColor(TEXT_3)
        .margin({ top: S_2 })
    }
    .width("100%")
    .padding({ top: S_6, bottom: S_6 })
    .alignItems(HorizontalAlign.Center)
  }
}

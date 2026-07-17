// ============================================================================
//  prototypes/chat/TypingIndicator.ets — AI 思考中三点动画
//  ----------------------------------------------------------------------------
//  职责: 三点跳动指示器,纯 ArkUI animation(0 JS 线程开销)。
//
//  UI:
//    ● ● ● 思考中
//    (三点 opacity 交替,1200ms 周期,200ms 错位)
//
//  依赖: common ColorTokens (PURPLE/PURPLE_LIGHT/TEXT_3)
//
//  来源: 从 AgentFloatWindow 内联代码拆出
//  ============================================================================

import { PURPLE, PURPLE_LIGHT, TEXT_3, S_1, S_2, S_3, R_MD, F_XS } from "common"

@Component
export struct TypingIndicator {
  build() {
    Row() {
      Row() {
        // 第一个点(立即开始 0 → 1 opacity)
        Circle({ width: 5, height: 5 })
          .fill(PURPLE).opacity(1)
          .animation({ duration: 1200, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate })
          .margin({ right: S_1 })

        // 第二个点(延迟 200ms)
        Circle({ width: 5, height: 5 })
          .fill(PURPLE).opacity(0.3)
          .animation({ duration: 1200, delay: 200, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate })
          .margin({ right: S_1 })

        // 第三个点(延迟 400ms)
        Circle({ width: 5, height: 5 })
          .fill(PURPLE).opacity(0.3)
          .animation({ duration: 1200, delay: 400, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate })

        // "思考中" 文字
        Text(" 思考中")
          .fontSize(F_XS)
          .fontColor(TEXT_3)
          .margin({ left: S_2 })
      }
      .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
      // 圆角:左下小角(AI 气泡尾巴)
      .borderRadius({ topLeft: R_MD + 4, topRight: R_MD + 4, bottomLeft: S_1, bottomRight: R_MD + 4 })
      .backgroundColor(PURPLE_LIGHT)

      Blank()
    }
    .width("100%")
    .margin({ top: S_2 })
  }
}

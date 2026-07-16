// chat/TypingIndicator.ets — typing 三点动画 (ArkUI animation)
import { PURPLE, PURPLE_LIGHT, TEXT_3, S_1, S_2, S_3, R_MD, F_XS } from "common"
@Component
export struct TypingIndicator {
  build() {
    Row() {
      Row() {
        Circle({ width: 5, height: 5 }).fill(PURPLE).opacity(1)
          .animation({ duration: 1200, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate })
          .margin({ right: S_1 })
        Circle({ width: 5, height: 5 }).fill(PURPLE).opacity(0.3)
          .animation({ duration: 1200, delay: 200, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate })
          .margin({ right: S_1 })
        Circle({ width: 5, height: 5 }).fill(PURPLE).opacity(0.3)
          .animation({ duration: 1200, delay: 400, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate })
        Text(" \u601D\u8003\u4E2D").fontSize(F_XS).fontColor(TEXT_3).margin({ left: S_2 })
      }
      .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
      .borderRadius({ topLeft: R_MD + 4, topRight: R_MD + 4, bottomLeft: S_1, bottomRight: R_MD + 4 })
      .backgroundColor(PURPLE_LIGHT)
      Blank()
    }.width("100%").margin({ top: S_2 })
  }
}

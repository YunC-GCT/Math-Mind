// ============================================================================
//  atoms/AiTabButton.ets — 中央 AI 渐变凸起圆原子组件
//  ----------------------------------------------------------------------------
//  职责: MINT→PURPLE 渐变圆形按钮，带 SHADOW_AI_BTN 光晕。
//  来源: 从 Index.ets AiBtn @Builder 转换为 @Component。
//  接口:
//    onTap — 点击回调
//  ============================================================================

import { MINT, PURPLE, BG_DARK, AI_BTN_SIZE, AI_ICON_SIZE, SHADOW_AI_BTN } from "common"

@Component
export struct AiTabButton {
  onTap: () => void = (): void => {}

  build() {
    Column() {
      Stack() {
        Image($r("app.media.ic_ai"))
          .width(AI_ICON_SIZE).height(AI_ICON_SIZE)
          .fillColor(BG_DARK)
      }
      .width(AI_BTN_SIZE).height(AI_BTN_SIZE)
      .borderRadius(AI_BTN_SIZE / 2)
      .linearGradient({
        angle: 135,
        colors: [[MINT, 0], [PURPLE, 1]],
      })
      .shadow(SHADOW_AI_BTN)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .onClick((): void => { this.onTap() })
  }
}

// ============================================================================
//  atoms/CameraCloseBtn.ets — 关闭按钮 (响应式)
//  ----------------------------------------------------------------------------
//  尺寸: SCREEN_W/8 圆形
// ============================================================================

import { F_LG, W_MEDIUM, SCREEN_W } from "common"

@Component
export struct CameraCloseBtn {
  onTap: () => void = (): void => {}

  build() {
    Stack() {
      Text("✕").fontSize(F_LG).fontWeight(W_MEDIUM).fontColor("rgba(255,255,255,0.8)")
    }
    .width(SCREEN_W / 8).height(SCREEN_W / 8)
    .borderRadius(SCREEN_W / 16)
    .backgroundColor("rgba(255,255,255,0.08)")
    .border({ width: 1, color: "rgba(255,255,255,0.1)" })
    .alignContent(Alignment.Center)
    .onClick((): void => { this.onTap() })
  }
}

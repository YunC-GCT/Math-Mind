// ============================================================================
//  atoms/CameraBackBtn.ets — 返回按钮 (响应式)
//  ----------------------------------------------------------------------------
//  尺寸: SCREEN_W/8 圆形
// ============================================================================

import { TEXT_2, F_3XL, SCREEN_W } from "common"

@Component
export struct CameraBackBtn {
  onTap: () => void = (): void => {}

  build() {
    Stack() {
      Text("‹").fontSize(F_3XL - 2).fontWeight(500).fontColor(TEXT_2)
    }
    .width(SCREEN_W / 8).height(SCREEN_W / 8)
    .borderRadius(F_LG)
    .alignContent(Alignment.Center)
    .onClick((): void => { this.onTap() })
  }
}

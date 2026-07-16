// ============================================================================
//  atoms/CameraConfirmBtn.ets — 确认按钮 (响应式)
//  ----------------------------------------------------------------------------
//  尺寸: SCREEN_W/8 高, 圆角 SCREEN_W/16
// ============================================================================

import { MINT, BG_DARK, F_BASE, F_XL, SCREEN_W } from "common"

@Component
export struct CameraConfirmBtn {
  @Prop busy: boolean = false
  onTap: () => void = (): void => {}

  build() {
    Row() {
      if (this.busy) {
        LoadingProgress().width(F_XL).height(F_XL).color(BG_DARK)
      } else {
        Text("✓ 使用").fontSize(F_BASE).fontColor(BG_DARK).fontWeight(700)
      }
    }
    .layoutWeight(1)
    .height(SCREEN_W / 8)
    .borderRadius(SCREEN_W / 16)
    .backgroundColor(MINT)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick((): void => { this.onTap() })
  }
}

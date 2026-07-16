// ============================================================================
//  atoms/CameraConfirmBtn.ets — 确认按钮 (响应式)
//  ----------------------------------------------------------------------------
//  尺寸: SCREEN_W/8 高, 圆角 SCREEN_W/16
// ============================================================================

import { MINT, BG_DARK, F_BASE, F_XL, SCREEN_W } from "common"
import { AppIcon } from "./AppIcon"

@Component
export struct CameraConfirmBtn {
  @Prop busy: boolean = false
  onTap: () => void = (): void => {}

  build() {
    Row() {
      if (this.busy) {
        LoadingProgress().width(F_XL).height(F_XL).color(BG_DARK)
      } else {
        AppIcon({ name: "check", iconSize: F_BASE, color: BG_DARK, strokeWidth: 2.2 })
        Text("使用").fontSize(F_BASE).fontColor(BG_DARK).fontWeight(700).margin({ left: 4 })
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

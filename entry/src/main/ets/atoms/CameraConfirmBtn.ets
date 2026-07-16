// ============================================================================
//  atoms/CameraConfirmBtn.ets — 确认按钮 (✓ 使用)
//  ----------------------------------------------------------------------------
//  职责: 绿色圆角确认按钮，支持 loading 态。
//  接口: @Prop busy; onTap — 点击回调
//  ============================================================================

import { MINT, BG_DARK, F_BASE, F_XL, CAM_CONFIRM_H } from "common"

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
    .height(CAM_CONFIRM_H)
    .borderRadius(CAM_CONFIRM_H / 2)
    .backgroundColor(MINT)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick((): void => { this.onTap() })
  }
}

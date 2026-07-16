// ============================================================================
//  atoms/CameraCloseBtn.ets — 关闭按钮 (✕)
//  ----------------------------------------------------------------------------
//  职责: 半透明圆形关闭按钮。
//  接口: onTap — 点击回调
//  ============================================================================

import { F_LG, W_MEDIUM, CAM_BTN_SIZE } from "common"

@Component
export struct CameraCloseBtn {
  onTap: () => void = (): void => {}

  build() {
    Stack() {
      Text("✕").fontSize(F_LG).fontWeight(W_MEDIUM).fontColor("rgba(255,255,255,0.8)")
    }
    .width(CAM_BTN_SIZE).height(CAM_BTN_SIZE)
    .borderRadius(CAM_BTN_SIZE / 2 - 2)
    .backgroundColor("rgba(255,255,255,0.08)")
    .border({ width: 1, color: "rgba(255,255,255,0.1)" })
    .alignContent(Alignment.Center)
    .onClick((): void => { this.onTap() })
  }
}

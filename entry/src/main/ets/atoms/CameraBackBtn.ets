// ============================================================================
//  atoms/CameraBackBtn.ets — 返回按钮 (‹)
//  ----------------------------------------------------------------------------
//  职责: 预览模式下返回相机拍摄界面。
//  接口: onTap — 点击回调
//  ============================================================================

import { TEXT_2, F_3XL, F_LG, CAM_BTN_SIZE } from "common"

@Component
export struct CameraBackBtn {
  onTap: () => void = (): void => {}

  build() {
    Stack() {
      Text("‹").fontSize(F_3XL - 2).fontWeight(500).fontColor(TEXT_2)
    }
    .width(CAM_BTN_SIZE).height(CAM_BTN_SIZE)
    .borderRadius(F_LG)
    .alignContent(Alignment.Center)
    .onClick((): void => { this.onTap() })
  }
}

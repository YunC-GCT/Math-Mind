// ============================================================================
//  atoms/CameraShutterBtn.ets — 相机快门按钮
//  ----------------------------------------------------------------------------
//  职责: 双层圆形快门 (MINT 外圈 + 实心内圈)。
//  接口: onTap — 点击回调
//  ============================================================================

import { MINT, S_2, CAM_SHUTTER_OUTER, CAM_SHUTTER_INNER } from "common"

@Component
export struct CameraShutterBtn {
  onTap: () => void = (): void => {}

  build() {
    Stack() {
      Stack()
        .width(CAM_SHUTTER_OUTER).height(CAM_SHUTTER_OUTER)
        .borderRadius(CAM_SHUTTER_OUTER / 2)
        .backgroundColor("transparent")
        .border({ width: S_2 * 3 / 8, color: MINT })
      Stack()
        .width(CAM_SHUTTER_INNER).height(CAM_SHUTTER_INNER)
        .borderRadius(CAM_SHUTTER_INNER / 2)
        .backgroundColor(MINT)
    }
    .width(CAM_SHUTTER_OUTER + S_2).height(CAM_SHUTTER_OUTER + S_2)
    .alignContent(Alignment.Center)
    .onClick((): void => { this.onTap() })
  }
}

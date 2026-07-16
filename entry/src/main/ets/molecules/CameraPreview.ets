// ============================================================================
//  molecules/CameraPreview.ets — 照片预览界面
//  ----------------------------------------------------------------------------
//  职责: 显示拍摄/选中的照片 + 底部信息 + 重拍/确认按钮。
//  数据流: @Prop capturedUri/capturedSrc/busy → 展示；onConfirm/onBack 回调。
//  依赖: CameraBackBtn, CameraConfirmBtn
//  ============================================================================

import {
  TEXT, TEXT_2, TEXT_4,
  S_2, S_4, S_6,
  F_XS, F_SM, F_MD, F_BASE,
  CAM_PREVIEW_BG, W_MEDIUM, W_SEMIBOLD, NOTE_ICON_SIZE,
  SCREEN_W,
} from "common"
import { CameraBackBtn } from "../atoms/CameraBackBtn"
import { CameraConfirmBtn } from "../atoms/CameraConfirmBtn"

@Component
export struct CameraPreview {
  @Prop capturedUri: string = ""
  @Prop capturedSrc: string = ""
  @Prop busy: boolean = false
  onConfirm: () => void = (): void => {}
  onBack: () => void = (): void => {}

  build() {
    Column() {
      // 顶栏: 返回 + 标题
      Row() {
        CameraBackBtn({ onTap: (): void => { this.onBack() } })
        Blank()
        Text("预览").fontSize(F_MD).fontColor(TEXT).fontWeight(W_SEMIBOLD)
        Blank()
        Column().width(NOTE_ICON_SIZE)
      }
      .width("100%").padding({ left: S_4, right: S_4, top: S_2, bottom: S_2 })

      // 图片预览
      Stack() {
        if (this.capturedUri.length > 0) {
          Column() {
            Image(this.capturedUri).width("100%").layoutWeight(1)
              .objectFit(ImageFit.Contain).backgroundColor("#FF000000")
            Row() {
              Text(this.capturedSrc === "camera" ? "已拍摄" : "从相册选择")
                .fontSize(F_SM).fontColor(TEXT_2)
              Blank()
              Text(this.capturedUri.split("/").pop() ?? "")
                .fontSize(F_XS - 1).fontColor(TEXT_4).maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: SCREEN_W / 2 })
            }
            .width("100%").padding({ left: S_4, right: S_4, top: S_2, bottom: S_2 })
          }.alignItems(HorizontalAlign.Center)
        }
      }
      .layoutWeight(1).width("100%").backgroundColor(CAM_PREVIEW_BG)

      // 底栏: 重拍 + 确认
      Row() {
        Text("重拍").fontSize(F_BASE).fontColor("rgba(255,255,255,0.7)").fontWeight(W_MEDIUM)
          .width(S_6 * 2 + S_3).textAlign(TextAlign.Center)
          .onClick((): void => { this.onBack() })
        Blank().width(12)
        CameraConfirmBtn({ busy: this.busy, onTap: (): void => { this.onConfirm() } })
      }
      .width("100%")
      .padding({ left: S_6, right: S_6, top: S_4, bottom: S_6 * 2 - S_2 })
      .alignItems(VerticalAlign.Center)
    }
    .width("100%").height("100%")
  }
}

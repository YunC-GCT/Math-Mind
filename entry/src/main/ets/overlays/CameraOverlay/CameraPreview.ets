import {
  TEXT, TEXT_2, TEXT_4,
  S_2, S_3, S_4, S_6,
  F_XS, F_SM, F_MD, F_BASE,
  CAM_PREVIEW_BG, W_MEDIUM, W_SEMIBOLD,
  SCREEN_W,
} from "common"
import { CameraBackBtn } from "./CameraBackBtn"
import { CameraConfirmBtn } from "./CameraConfirmBtn"

@Component
export struct CameraPreview {
  @Prop capturedUri: string = ""
  @Prop capturedSrc: string = ""
  @Prop busy: boolean = false
  onConfirm: () => void = (): void => {}
  onBack: () => void = (): void => {}

  build() {
    Column() {
      Row() {
        CameraBackBtn({ onTap: (): void => { this.onBack() } })
        Blank()
        Text("\u9884\u89c8")
          .fontSize(F_MD)
          .fontColor(TEXT)
          .fontWeight(W_SEMIBOLD)
        Blank()
        Column().width(SCREEN_W / 8).height(SCREEN_W / 8)
      }
      .width("100%")
      .padding({ left: S_3, right: S_3, top: S_3, bottom: S_3 })
      .alignItems(VerticalAlign.Center)

      Stack() {
        if (this.capturedUri.length > 0) {
          Column() {
            Image(this.capturedUri)
              .width("100%")
              .layoutWeight(1)
              .objectFit(ImageFit.Contain)
              .backgroundColor("#FF000000")
            Row() {
              Text(this.capturedSrc === "camera" ? "\u5df2\u62cd\u6444" : "\u4ece\u76f8\u518c\u9009\u62e9")
                .fontSize(F_SM)
                .fontColor(TEXT_2)
              Blank()
              Text(this.capturedUri.split("/").pop() ?? "")
                .fontSize(F_XS - 1)
                .fontColor(TEXT_4)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: SCREEN_W / 2 })
            }
            .width("100%")
            .padding({ left: S_4, right: S_4, top: S_2, bottom: S_2 })
          }
          .alignItems(HorizontalAlign.Center)
        }
      }
      .layoutWeight(1)
      .width("100%")
      .backgroundColor(CAM_PREVIEW_BG)

      Row() {
        Text("\u91cd\u62cd")
          .fontSize(F_BASE)
          .fontColor("rgba(255,255,255,0.72)")
          .fontWeight(W_MEDIUM)
          .width(SCREEN_W / 5)
          .textAlign(TextAlign.Center)
          .onClick((): void => { this.onBack() })
        Blank().width(S_3)
        CameraConfirmBtn({ busy: this.busy, onTap: (): void => { this.onConfirm() } })
      }
      .width("100%")
      .padding({ left: S_4, right: S_4, top: S_4, bottom: S_6 })
      .alignItems(VerticalAlign.Center)
    }
    .width("100%")
    .height("100%")
  }
}
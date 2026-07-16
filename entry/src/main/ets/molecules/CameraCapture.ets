// ============================================================================
//  molecules/CameraCapture.ets — 相机拍摄界面 (响应式)
//  ----------------------------------------------------------------------------
//  尺寸策略: 基于 SCREEN_W 等比缩放, 适配各种手机。
//  SCREEN_W=377 (Pura90 基准) → 所有尺寸 = SCREEN_W * 比例
// ============================================================================

import { F_LG, F_BASE, F_XS, W_MEDIUM, S_3, S_4, S_6, SCREEN_W } from "common"
import { CameraCloseBtn } from "../atoms/CameraCloseBtn"
import { CameraAlbumBtn } from "../atoms/CameraAlbumBtn"
import { CameraShutterBtn } from "../atoms/CameraShutterBtn"
import { ViewfinderCorners } from "../atoms/ViewfinderCorners"

@Component
export struct CameraCapture {
  onClose: () => void = (): void => {}
  onShutter: () => void = (): void => {}
  onAlbum: () => void = (): void => {}

  build() {
    Column() {
      Row() {
        CameraCloseBtn({ onTap: (): void => { this.onClose() } })
        Blank()
        Stack() {
          Text("⟳").fontSize(F_LG).fontWeight(W_MEDIUM).fontColor("rgba(255,255,255,0.6)")
        }
        .width(SCREEN_W / 8).height(SCREEN_W / 8)
        .borderRadius(SCREEN_W / 16)
        .backgroundColor("rgba(255,255,255,0.05)").alignContent(Alignment.Center)
      }
      .width("100%").padding({ left: S_4, right: S_4, top: S_4, bottom: S_4 })

      Stack() {
        Column() {
          Image($r("app.media.ic_camera"))
            .width(SCREEN_W / 7).height(SCREEN_W / 7)
            .fillColor("rgba(255,255,255,0.35)")
          Text("将题目对准框内").fontSize(F_BASE).fontColor("rgba(255,255,255,0.5)").margin({ top: S_4 })
          Text("点击下方快门拍摄").fontSize(F_XS).fontColor("rgba(255,255,255,0.35)").margin({ top: S_3 })
        }.alignItems(HorizontalAlign.Center)
        ViewfinderCorners()
      }
      .layoutWeight(1).width("100%").backgroundColor("#FF000000")

      Row() {
        CameraAlbumBtn({ onTap: (): void => { this.onAlbum() } })
        CameraShutterBtn({ onTap: (): void => { this.onShutter() } })
        Column().width(SCREEN_W / 7)
      }
      .width("100%")
      .padding({ left: S_4, right: S_4, top: S_4, bottom: S_6 })
      .justifyContent(FlexAlign.SpaceBetween).alignItems(VerticalAlign.Center)
    }
    .width("100%").height("100%")
  }
}

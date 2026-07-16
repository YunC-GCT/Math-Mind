// ============================================================================
//  molecules/CameraCapture.ets — 相机拍摄界面
//  ----------------------------------------------------------------------------
//  职责: 组装顶栏(关闭+翻转) + 取景框 + 底栏(相册+快门)。
//  数据流: onClose/onShutter/onAlbum 回调通知父组件。
//  依赖: CameraCloseBtn, CameraAlbumBtn, CameraShutterBtn, ViewfinderCorners
// ============================================================================

import { F_LG, F_BASE, F_XS, W_MEDIUM, S_1, S_2, S_3, S_4, S_6, CAM_BTN_SIZE, CAM_SHUTTER_INNER, CAM_ALBUM_SIZE } from "common"
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
      // 顶栏: 关闭 + 翻转
      Row() {
        CameraCloseBtn({ onTap: (): void => { this.onClose() } })
        Blank()
        Stack() {
          Text("⟳").fontSize(F_LG).fontWeight(W_MEDIUM).fontColor("rgba(255,255,255,0.6)")
        }
        .width(CAM_BTN_SIZE).height(CAM_BTN_SIZE).borderRadius(CAM_BTN_SIZE / 2 - 2)
        .backgroundColor("rgba(255,255,255,0.05)").alignContent(Alignment.Center)
      }
      .width("100%").padding({ left: S_3, right: S_3, top: S_4, bottom: S_2 })

      // 预览区 + 取景框
      Stack() {
        Column() {
          Image($r("app.media.ic_camera"))
            .width(CAM_SHUTTER_INNER).height(CAM_SHUTTER_INNER)
            .fillColor("rgba(255,255,255,0.35)")
          Text("将题目对准框内").fontSize(F_BASE).fontColor("rgba(255,255,255,0.5)").margin({ top: S_4 })
          Text("点击下方快门拍摄").fontSize(F_XS).fontColor("rgba(255,255,255,0.35)").margin({ top: S_2 })
        }.alignItems(HorizontalAlign.Center)
        ViewfinderCorners()
      }
      .layoutWeight(1).width("100%").backgroundColor("#FF000000").margin({ top: S_2 })

      // 底栏: 相册 + 快门 + 对称占位
      Row() {
        CameraAlbumBtn({ onTap: (): void => { this.onAlbum() } })
        CameraShutterBtn({ onTap: (): void => { this.onShutter() } })
        Column().width(CAM_ALBUM_SIZE)
      }
      .width("100%")
      .padding({ left: S_4, right: S_4, top: S_4, bottom: S_4 })
      .justifyContent(FlexAlign.SpaceBetween).alignItems(VerticalAlign.Center)
    }
    .width("100%").height("100%")
  }
}

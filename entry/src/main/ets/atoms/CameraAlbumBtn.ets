// ============================================================================
//  atoms/CameraAlbumBtn.ets — 相册按钮 (响应式)
//  ----------------------------------------------------------------------------
//  尺寸: SCREEN_W/7 圆形
// ============================================================================

import { SCREEN_W } from "common"

@Component
export struct CameraAlbumBtn {
  onTap: () => void = (): void => {}

  build() {
    Stack() {
      Image($r("app.media.ic_album"))
        .width(SCREEN_W / 14).height(SCREEN_W / 14)
        .fillColor("#FFFFFFFF")
    }
    .width(SCREEN_W / 7).height(SCREEN_W / 7)
    .borderRadius(SCREEN_W / 14)
    .backgroundColor("rgba(255,255,255,0.1)")
    .border({ width: 1, color: "rgba(255,255,255,0.15)" })
    .alignContent(Alignment.Center)
    .onClick((): void => { this.onTap() })
  }
}

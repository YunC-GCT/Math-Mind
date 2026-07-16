// ============================================================================
//  atoms/CameraAlbumBtn.ets — 相册按钮
//  ----------------------------------------------------------------------------
//  职责: 圆形相册图标按钮。
//  接口: onTap — 点击回调
//  ============================================================================

import { CAM_ALBUM_SIZE } from "common"

@Component
export struct CameraAlbumBtn {
  onTap: () => void = (): void => {}

  build() {
    Stack() {
      Image($r("app.media.ic_album"))
        .width(CAM_ALBUM_SIZE / 2 - 2).height(CAM_ALBUM_SIZE / 2 - 2)
        .fillColor("#FFFFFFFF")
    }
    .width(CAM_ALBUM_SIZE).height(CAM_ALBUM_SIZE)
    .borderRadius(CAM_ALBUM_SIZE / 2)
    .backgroundColor("rgba(255,255,255,0.1)")
    .border({ width: 1, color: "rgba(255,255,255,0.15)" })
    .alignContent(Alignment.Center)
    .onClick((): void => { this.onTap() })
  }
}

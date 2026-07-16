// ============================================================================
//  prototypes/CameraOverlay.ets — 相机浮窗装配层
//  ----------------------------------------------------------------------------
//  职责: 持有相机状态 + 拍照/选图业务逻辑，build() 仅组装子组件。
//  数据流: @State → CameraCapture/CameraPreview @Prop，回调 ← 子组件。
//  依赖:
//    molecules: CameraCapture, CameraPreview
// ============================================================================

import { S_1, S_2, S_5, S_6, TEXT_4, CAM_MASK, CAM_OVERLAY_BG } from "common"
import { cameraPicker, camera } from "@kit.CameraKit"
import { photoAccessHelper } from "@kit.MediaLibraryKit"
import { common } from "@kit.AbilityKit"
import { promptAction } from "@kit.ArkUI"
import { CameraCapture } from "../molecules/CameraCapture"
import { CameraPreview } from "../molecules/CameraPreview"

type CameraState = "camera" | "preview"

function mockCaptureUri(src: "camera" | "album"): string {
  return "mock_" + src + "_" + Date.now() + ".jpg"
}

@Component
export struct CameraOverlay {
  @State state: CameraState = "camera"
  @State capturedUri: string = ""
  @State capturedSrc: "camera" | "album" | "" = ""
  @State busy: boolean = false
  onClose: () => void = (): void => {}
  onConfirm: (uri: string, src: "camera" | "album") => void = (): void => {}

  build() {
    Stack() {
      Column().width("100%").height("100%").backgroundColor(CAM_MASK)
      Column() {
        // drag bar
        Row() {
          Row().width(S_5 * 2).height(S_1).borderRadius(S_1 / 2).backgroundColor(TEXT_4)
        }.width("100%").height(S_6).margin({ top: S_2 }).justifyContent(FlexAlign.Center)

        if (this.state === "camera") {
          CameraCapture({
            onClose: (): void => { this.onClose() },
            onShutter: (): void => { this.takePhoto() },
            onAlbum: (): void => { this.pickAlbum() },
          })
        } else {
          CameraPreview({
            capturedUri: this.capturedUri,
            capturedSrc: this.capturedSrc,
            busy: this.busy,
            onConfirm: (): void => {
              if (!this.busy && this.capturedUri.length > 0) {
                this.busy = true
                this.onConfirm(this.capturedUri, this.capturedSrc === "camera" ? "camera" : "album")
              }
            },
            onBack: (): void => {
              this.state = "camera"; this.capturedUri = ""; this.capturedSrc = ""
            },
          })
        }
      }
      .width("100%").height("100%").backgroundColor(CAM_OVERLAY_BG)
    }.width("100%").height("100%")
  }

  // ========== 行为 ==========
  private takePhoto = async (): Promise<void> => {
    this.busy = true
    try {
      const ctx = getContext(this) as common.UIAbilityContext
      const result = await cameraPicker.pick(ctx, [cameraPicker.PickerMediaType.PHOTO], {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK,
      })
      if (result !== undefined && result.resultUri.length > 0) {
        this.capturedUri = result.resultUri; this.capturedSrc = "camera"; this.state = "preview"; return
      }
    } catch (e) { promptAction.showToast({ message: "模拟器不支持相机，已使用模拟图片", duration: 2000 }) }
    finally { this.busy = false }
    this.capturedUri = mockCaptureUri("camera"); this.capturedSrc = "camera"; this.state = "preview"
  }

  private pickAlbum = async (): Promise<void> => {
    this.busy = true
    try {
      const ctx = getContext(this) as common.UIAbilityContext
      const picker = new photoAccessHelper.PhotoViewPicker()
      const result = await picker.select({ MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE, maxSelectNumber: 1 })
      if (result.photoUris.length > 0) {
        this.capturedUri = result.photoUris[0]; this.capturedSrc = "album"; this.state = "preview"; return
      }
    } catch (e) { /* 用户取消 */ } finally { this.busy = false }
    this.capturedUri = mockCaptureUri("album"); this.capturedSrc = "album"; this.state = "preview"
  }
}

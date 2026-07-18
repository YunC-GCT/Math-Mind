// ============================================================================
//  overlays/CameraOverlay/CameraOverlay.ets - camera overlay container
// ----------------------------------------------------------------------------
//  Owns camera state and album/camera actions. Child components only render UI.
// ============================================================================

import { S_1, S_2, S_5, S_6, TEXT_4, CAM_MASK, CAM_OVERLAY_BG } from "common"
import { cameraPicker, camera } from "@kit.CameraKit"
import { photoAccessHelper } from "@kit.MediaLibraryKit"
import { common } from "@kit.AbilityKit"
import { promptAction } from "@kit.ArkUI"
import { CameraCapture } from "./CameraCapture"
import { CameraPreview } from "./CameraPreview"

type CameraState = "camera" | "preview"
type CaptureSource = "camera" | "album"

@Component
export struct CameraOverlay {
  @State state: CameraState = "camera"
  @State capturedUri: string = ""
  @State capturedSrc: CaptureSource | "" = ""
  @State busy: boolean = false
  onClose: () => void = (): void => {}
  onConfirm: (uri: string, src: CaptureSource) => void = (): void => {}

  build() {
    Stack() {
      Column().width("100%").height("100%").backgroundColor(CAM_MASK)
      Column() {
        Row() {
          Row().width(S_5 * 2).height(S_1).borderRadius(S_1 / 2).backgroundColor(TEXT_4)
        }
        .width("100%")
        .height(S_6)
        .margin({ top: S_2 })
        .justifyContent(FlexAlign.Center)

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
            onConfirm: (): void => { this.confirmCapture() },
            onBack: (): void => { this.resetCapture() },
          })
        }
      }
      .width("100%")
      .height("100%")
      .backgroundColor(CAM_OVERLAY_BG)
    }
    .width("100%")
    .height("100%")
  }

  private confirmCapture(): void {
    if (this.busy || this.capturedUri.length === 0 || this.capturedSrc.length === 0) {
      return
    }

    this.busy = true
    this.onConfirm(this.capturedUri, this.capturedSrc === "camera" ? "camera" : "album")
  }

  private resetCapture(): void {
    this.state = "camera"
    this.capturedUri = ""
    this.capturedSrc = ""
    this.busy = false
  }

  private takePhoto = async (): Promise<void> => {
    this.busy = true
    try {
      const ctx = getContext(this) as common.UIAbilityContext
      const result = await cameraPicker.pick(ctx, [cameraPicker.PickerMediaType.PHOTO], {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK,
      })

      if (result !== undefined && result.resultUri.length > 0) {
        this.capturedUri = result.resultUri
        this.capturedSrc = "camera"
        this.state = "preview"
        return
      }

      this.showToast("\u672a\u83b7\u53d6\u5230\u7167\u7247", 1500)
    } catch (_e) {
      this.showToast("\u76f8\u673a\u4e0d\u53ef\u7528\uff0c\u8bf7\u4ece\u76f8\u518c\u9009\u62e9", 2000)
    } finally {
      this.busy = false
    }
  }

  private pickAlbum = async (): Promise<void> => {
    this.busy = true
    try {
      const picker = new photoAccessHelper.PhotoViewPicker()
      const result = await picker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1,
      })

      if (result.photoUris.length > 0) {
        this.capturedUri = result.photoUris[0]
        this.capturedSrc = "album"
        this.state = "preview"
        return
      }

      this.showToast("\u672a\u9009\u62e9\u56fe\u7247", 1500)
    } catch (_e) {
      // User cancellation or permission denial is non-fatal here.
    } finally {
      this.busy = false
    }
  }

  private showToast(message: string, duration: number): void {
    try {
      promptAction.showToast({ message: message, duration: duration })
    } catch (_e) {}
  }
}


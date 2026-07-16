// ============================================================================
//  prototypes/CameraOverlay.ets — 相机浮层
//  ----------------------------------------------------------------------------
//  职责: 系统相机/相册拍照选图，含取景框 UI 和预览确认流程。
//  @Builder 保留原因: 9 个 @Builder 直接访问 this.busy/capturedUri/state，
//    抽离需穿 5+ 个 @Prop + callback，无复用收益。
//  ============================================================================

import {
  MINT, BG_DARK, TEXT, TEXT_2, TEXT_4,
  S_1, S_2, S_3, S_4, S_5, S_6,
  F_XS, F_SM, F_BASE, F_MD, F_LG, F_3XL,
  W_MEDIUM, W_SEMIBOLD, W_BOLD,
  CAM_SHUTTER_OUTER, CAM_SHUTTER_INNER, CAM_BTN_SIZE, CAM_ALBUM_SIZE, CAM_CONFIRM_H,
  CAM_OVERLAY_BG, CAM_PREVIEW_BG, CAM_MASK,
  SCREEN_W, NOTE_ICON_SIZE,
} from "common"
import { cameraPicker, camera } from "@kit.CameraKit"
import { photoAccessHelper } from "@kit.MediaLibraryKit"
import { common } from "@kit.AbilityKit"
import { promptAction } from "@kit.ArkUI"

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

        if (this.state === "camera") { this.CameraView() } else { this.PreviewView() }
      }
      .width("100%").height("100%").backgroundColor(CAM_OVERLAY_BG)
    }.width("100%").height("100%")
  }

  @Builder CameraView() {
    Column() {
      Row() { this.CloseBtn(); Blank(); this.FlipBtn() }
        .width("100%").padding({ left: S_5, right: S_5, top: S_5, bottom: S_5 })
      Stack() {
        Column() {
          Image($r("app.media.ic_camera")).width(CAM_SHUTTER_INNER + 2).height(CAM_SHUTTER_INNER + 2)
            .fillColor("rgba(255,255,255,0.35)")
          Text("将题目对准框内").fontSize(F_BASE).fontColor("rgba(255,255,255,0.5)").margin({ top: S_3 + 2 })
          Text("点击下方快门拍摄").fontSize(F_XS).fontColor("rgba(255,255,255,0.35)").margin({ top: S_1 })
        }.alignItems(HorizontalAlign.Center)
        this.ViewfinderCorners()
      }.layoutWeight(1).width("100%").backgroundColor("#FF000000").margin({ top: S_2 })
      Row() { this.AlbumBtn(); this.ShutterBtn(); Column().width(CAM_SHUTTER_INNER + 2) }
        .width("100%").padding({ left: S_6 + S_2, right: S_6 + S_2, top: S_6, bottom: S_6 * 2 + 2 })
        .justifyContent(FlexAlign.SpaceBetween).alignItems(VerticalAlign.Center)
    }.width("100%").height("100%")
  }

  @Builder PreviewView() {
    Column() {
      Row() { this.BackBtn(); Blank(); Text("预览").fontSize(F_MD).fontColor(TEXT).fontWeight(W_SEMIBOLD); Blank(); Column().width(NOTE_ICON_SIZE) }
        .width("100%").padding({ left: S_4, right: S_4, top: S_2, bottom: S_2 })
      Stack() {
        if (this.capturedUri.length > 0) {
          Column() {
            Image(this.capturedUri).width("100%").layoutWeight(1).objectFit(ImageFit.Contain).backgroundColor("#FF000000")
            Row() {
              Text(this.capturedSrc === "camera" ? "已拍摄" : "从相册选择").fontSize(F_SM).fontColor(TEXT_2)
              Blank()
              Text(this.capturedUri.split("/").pop() ?? "").fontSize(F_XS - 1).fontColor(TEXT_4)
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).constraintSize({ maxWidth: SCREEN_W / 2 })
            }.width("100%").padding({ left: S_4, right: S_4, top: S_2, bottom: S_2 })
          }.alignItems(HorizontalAlign.Center)
        }
      }.layoutWeight(1).width("100%").backgroundColor(CAM_PREVIEW_BG)
      Row() { this.RetakeBtn(); Blank().width(S_3); this.ConfirmBtn() }
        .width("100%").padding({ left: S_6, right: S_6, top: S_4, bottom: S_6 * 2 - S_2 })
        .alignItems(VerticalAlign.Center)
    }.width("100%").height("100%")
  }

  @Builder CloseBtn() {
    Stack() {
      Text("✕").fontSize(F_LG).fontWeight(W_MEDIUM).fontColor("rgba(255,255,255,0.8)")
    }.width(CAM_BTN_SIZE).height(CAM_BTN_SIZE).borderRadius(S_5)
      .backgroundColor("rgba(255,255,255,0.08)").border({ width: 1, color: "rgba(255,255,255,0.1)" })
      .alignContent(Alignment.Center).onClick((): void => this.onClose())
  }

  @Builder FlipBtn() {
    Stack() {
      Text("⟳").fontSize(F_LG).fontWeight(W_MEDIUM).fontColor("rgba(255,255,255,0.6)")
    }.width(CAM_BTN_SIZE).height(CAM_BTN_SIZE).borderRadius(S_5)
      .backgroundColor("rgba(255,255,255,0.05)").alignContent(Alignment.Center)
  }

  @Builder AlbumBtn() {
    Stack() {
      Image($r("app.media.ic_album")).width(S_6).height(S_6).fillColor("#FFFFFFFF")
    }.width(CAM_ALBUM_SIZE).height(CAM_ALBUM_SIZE).borderRadius(CAM_ALBUM_SIZE / 2)
      .backgroundColor("rgba(255,255,255,0.1)").border({ width: 1, color: "rgba(255,255,255,0.15)" })
      .alignContent(Alignment.Center)
      .onClick((): void => { if (!this.busy) { this.pickAlbum() } })
  }

  @Builder ShutterBtn() {
    Stack() {
      Stack().width(CAM_SHUTTER_OUTER).height(CAM_SHUTTER_OUTER).borderRadius(CAM_SHUTTER_OUTER / 2)
        .backgroundColor("transparent").border({ width: S_1 * 3 / 4, color: MINT })
      Stack().width(CAM_SHUTTER_INNER).height(CAM_SHUTTER_INNER).borderRadius(CAM_SHUTTER_INNER / 2).backgroundColor(MINT)
    }.width(CAM_SHUTTER_OUTER + S_2).height(CAM_SHUTTER_OUTER + S_2).alignContent(Alignment.Center)
      .onClick((): void => { if (!this.busy) { this.takePhoto() } })
  }

  @Builder RetakeBtn() {
    Text("重拍").fontSize(F_BASE).fontColor("rgba(255,255,255,0.7)").fontWeight(W_MEDIUM)
      .width(S_6 * 2 + S_3).textAlign(TextAlign.Center)
      .onClick((): void => { this.state = "camera"; this.capturedUri = ""; this.capturedSrc = "" })
  }

  @Builder ConfirmBtn() {
    Row() {
      if (this.busy) { LoadingProgress().width(S_5).height(S_5).color(BG_DARK) }
      else { Text("✓ 使用").fontSize(F_BASE).fontColor(BG_DARK).fontWeight(W_BOLD) }
    }.layoutWeight(1).height(CAM_CONFIRM_H).borderRadius(CAM_CONFIRM_H / 2).backgroundColor(MINT)
      .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
      .onClick((): void => {
        if (!this.busy && this.capturedUri.length > 0) {
          this.busy = true
          this.onConfirm(this.capturedUri, this.capturedSrc === "camera" ? "camera" : "album")
        }
      })
  }

  @Builder BackBtn() {
    Stack() {
      Text("‹").fontSize(F_3XL - 2).fontWeight(W_MEDIUM).fontColor(TEXT_2)
    }.width(CAM_BTN_SIZE).height(CAM_BTN_SIZE).borderRadius(F_LG).alignContent(Alignment.Center)
      .onClick((): void => { this.state = "camera"; this.capturedUri = ""; this.capturedSrc = "" })
  }

  @Builder ViewfinderCorners() {
    Stack() {
      // 左上
      Column().width(S_6).height(S_1 / 2).backgroundColor(MINT).position({ x: S_6, y: S_6 })
      Column().width(S_1 / 2).height(S_6).backgroundColor(MINT).position({ x: S_6, y: S_6 })
      // 右上
      Column().width(S_6).height(S_1 / 2).backgroundColor(MINT).position({ x: "100%", y: S_6 }).markAnchor({ x: S_6, y: 0 })
      Column().width(S_1 / 2).height(S_6).backgroundColor(MINT).position({ x: "100%", y: S_6 }).markAnchor({ x: 0, y: 0 })
      // 左下
      Column().width(S_6).height(S_1 / 2).backgroundColor(MINT).position({ x: S_6, y: "100%" }).markAnchor({ x: 0, y: S_1 / -2 })
      Column().width(S_1 / 2).height(S_6).backgroundColor(MINT).position({ x: S_6, y: "100%" }).markAnchor({ x: 0, y: -S_6 })
      // 右下
      Column().width(S_6).height(S_1 / 2).backgroundColor(MINT).position({ x: "100%", y: "100%" }).markAnchor({ x: -S_6, y: S_1 / -2 })
      Column().width(S_1 / 2).height(S_6).backgroundColor(MINT).position({ x: "100%", y: "100%" }).markAnchor({ x: 0, y: -S_6 })
    }.width("100%").height("100%")
  }

  // ========== 行为 ==========
  private takePhoto = async (): Promise<void> => {
    this.busy = true
    try {
      const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
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
      const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
      const picker = new photoAccessHelper.PhotoViewPicker()
      const result = await picker.select({ MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE, maxSelectNumber: 1 })
      if (result.photoUris.length > 0) {
        this.capturedUri = result.photoUris[0]; this.capturedSrc = "album"; this.state = "preview"; return
      }
    } catch (e) { /* 用户取消 */ } finally { this.busy = false }
    this.capturedUri = mockCaptureUri("album"); this.capturedSrc = "album"; this.state = "preview"
  }
}

import { MINT, BG_DARK, F_BASE, F_XL, SCREEN_W } from "common"

@Component
export struct CameraConfirmBtn {
  @Prop busy: boolean = false
  onTap: () => void = (): void => {}

  build() {
    Row() {
      if (this.busy) {
        LoadingProgress()
          .width(F_XL)
          .height(F_XL)
          .color(BG_DARK)
      } else {
        Text("\u2713")
          .fontSize(F_BASE)
          .fontColor(BG_DARK)
          .fontWeight(700)
        Text("\u4f7f\u7528")
          .fontSize(F_BASE)
          .fontColor(BG_DARK)
          .fontWeight(700)
          .margin({ left: 4 })
      }
    }
    .layoutWeight(1)
    .height(SCREEN_W / 8)
    .borderRadius(SCREEN_W / 16)
    .backgroundColor(MINT)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick((): void => { this.onTap() })
  }
}
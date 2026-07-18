import { TEXT_2, F_MD, SCREEN_W } from "common"

@Component
export struct CameraBackBtn {
  onTap: () => void = (): void => {}

  build() {
    Stack() {
      Text("<")
        .fontSize(F_MD + 4)
        .fontWeight(700)
        .fontColor(TEXT_2)
    }
    .width(SCREEN_W / 8)
    .height(SCREEN_W / 8)
    .borderRadius(SCREEN_W / 16)
    .backgroundColor("rgba(255,255,255,0.08)")
    .border({ width: 1, color: "rgba(255,255,255,0.1)" })
    .alignContent(Alignment.Center)
    .onClick((): void => { this.onTap() })
  }
}
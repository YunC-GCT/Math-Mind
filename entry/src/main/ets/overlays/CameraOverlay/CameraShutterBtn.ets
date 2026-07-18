import { MINT, S_2, SCREEN_W } from "common"

@Component
export struct CameraShutterBtn {
  onTap: () => void = (): void => {}

  build() {
    Stack() {
      Stack()
        .width(SCREEN_W / 5.5)
        .height(SCREEN_W / 5.5)
        .borderRadius(SCREEN_W / 11)
        .backgroundColor("transparent")
        .border({ width: S_2 * 3 / 8, color: MINT })
      Stack()
        .width(SCREEN_W / 7)
        .height(SCREEN_W / 7)
        .borderRadius(SCREEN_W / 14)
        .backgroundColor(MINT)
    }
    .width(SCREEN_W / 5)
    .height(SCREEN_W / 5)
    .alignContent(Alignment.Center)
    .onClick((): void => { this.onTap() })
  }
}
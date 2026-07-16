import { BG_DARK, TEXT, S_2, S_4, F_MD, W_MEDIUM, HEADER_H } from "common"
import { HexLogo } from "../../atoms/HexLogo"

@Component
export struct HomeTopBar {
  @Prop statusBarHeight: number = 0

  build() {
    Column() {
      Row()
        .width("100%")
        .height(this.statusBarHeight)
        .backgroundColor(BG_DARK)

      Row() {
        HexLogo()
        Text("MathMind")
          .fontFamily("HarmonyOS Sans Condensed")
          .fontSize(F_MD + 2)
          .fontWeight(W_MEDIUM)
          .fontColor(TEXT)
          .margin({ left: S_2 })
      }
      .width("100%")
      .height(HEADER_H)
      .padding({ left: S_4, right: S_4 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(BG_DARK)
    }
    .width("100%")
  }
}

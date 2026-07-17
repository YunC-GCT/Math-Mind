import {
  BG_DARK, TEXT, TEXT_3,
  S_4, S_5,
  F_XS, F_MD,
  W_SEMIBOLD,
} from "common"

@Component
export struct NotesHeader {
  @Prop statusBarHeight: number = 0
  @Prop count: number = 0

  build() {
    Column() {
      Row().width("100%").height(this.statusBarHeight).backgroundColor(BG_DARK)

      Row() {
        Text("全部笔记")
          .fontSize(F_MD)
          .fontWeight(W_SEMIBOLD)
          .fontColor(TEXT)
        Blank()
        Text(this.count + " 条")
          .fontSize(F_XS)
          .fontColor(TEXT_3)
      }
      .width("100%")
      .padding({ left: S_5, right: S_5, top: S_4, bottom: S_4 })
    }
    .width("100%")
  }
}
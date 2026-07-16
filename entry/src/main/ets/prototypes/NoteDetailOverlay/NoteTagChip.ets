import { MINT, MINT_GLOW, S_2, S_3, R_FULL, F_XS } from "common"

@Component
export struct NoteTagChip {
  @Prop tag: string = ""

  build() {
    Text("#" + this.tag)
      .fontSize(F_XS)
      .fontColor(MINT)
      .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
      .borderRadius(R_FULL)
      .backgroundColor(MINT_GLOW)
      .margin({ right: S_2, bottom: S_2 })
  }
}

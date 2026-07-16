import { MINT, TEXT_2, S_2, S_3, F_SM, F_BASE, W_BOLD } from "common"

export interface Section {
  title: string
  content: string
}

@Component
export struct NoteSectionView {
  @Prop title: string = ""
  @Prop content: string = ""

  build() {
    Column() {
      Text(this.title)
        .fontSize(F_SM).fontWeight(W_BOLD)
        .fontColor(MINT).letterSpacing(0.5)
        .width("100%")
        .margin({ top: S_3, bottom: S_2 })

      Text(this.content.length > 0 ? this.content : "—")
        .fontSize(F_BASE)
        .fontColor(TEXT_2)
        .lineHeight(22)
        .width("100%")
    }
    .width("100%")
    .alignItems(HorizontalAlign.Start)
  }
}

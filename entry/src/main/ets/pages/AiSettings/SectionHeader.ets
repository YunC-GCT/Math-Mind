// 设置页 · 分组标题
import { TEXT, TEXT_4, F_XS, F_SM, W_SEMIBOLD, S_1, S_2, S_5 } from "common"
@Component
export struct SectionHeader {
  @Prop title: string = ""
  @Prop desc: string = ""
  build() {
    Column() {
      Text(this.title).fontSize(F_SM).fontWeight(W_SEMIBOLD).fontColor(TEXT)
      if (this.desc) { Text(this.desc).fontSize(F_XS).fontColor(TEXT_4).margin({ top: S_1 / 2 }) }
    }.alignItems(HorizontalAlign.Start).width("100%").padding({ left: S_5, right: S_2, top: S_5, bottom: S_2 })
  }
}

// 设置页 · 分组标题
import { TEXT, TEXT_4, F_XS, F_SM, W_SEMIBOLD, S_2 } from "common"
@Component
export struct SectionHeader {
  @Prop title: string = ""
  @Prop desc: string = ""
  build() {
    Column() {
      Text(this.title).fontSize(F_SM).fontWeight(W_SEMIBOLD).fontColor(TEXT)
      if (this.desc) { Text(this.desc).fontSize(F_XS).fontColor(TEXT_4).margin({ top: 2 }) }
    }.alignItems(HorizontalAlign.Start).width("100%").padding({ left: 20, right: S_2, top: 20, bottom: 8 })
  }
}

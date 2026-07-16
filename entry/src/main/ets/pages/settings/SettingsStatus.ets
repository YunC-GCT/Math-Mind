// 设置页 · 连接状态行
import { MINT, BG_CARD, TEXT, TEXT_3, TEXT_4, F_XS, F_BASE, W_SEMIBOLD, S_4, R_LG } from "common"
@Component
export struct SettingsStatus {
  @Prop configured: boolean = false
  @Prop statusText: string = "未配置"
  build() {
    Row() {
      Column() {
        Text("连接状态").fontSize(F_XS).fontColor(TEXT_3).margin({ bottom: 4 })
        Text(this.statusText).fontSize(F_BASE).fontWeight(W_SEMIBOLD).fontColor(this.configured ? MINT : TEXT_4)
      }.alignItems(HorizontalAlign.Start)
      Blank()
      Circle({ width: 10, height: 10 }).fill(this.configured ? MINT : TEXT_4)
    }.width("100%").padding(S_4).borderRadius(R_LG).backgroundColor(BG_CARD).margin({ left: 8, right: 8 })
  }
}

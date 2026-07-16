// 设置页 · 连接状态行
import { MINT, BG_CARD, TEXT_3, TEXT_4, F_XS, F_BASE, W_SEMIBOLD, S_1, S_2, S_4, R_LG } from "common"
@Component
export struct ConnectionStatus {
  @Prop configured: boolean = false
  @Prop statusText: string = "未配置"
  build() {
    Row() {
      Column() {
        Text("连接状态").fontSize(F_XS).fontColor(TEXT_3).margin({ bottom: S_1 })
        Text(this.statusText).fontSize(F_BASE).fontWeight(W_SEMIBOLD).fontColor(this.configured ? MINT : TEXT_4)
      }.alignItems(HorizontalAlign.Start)
      Blank()
      Circle({ width: S_3 - 2, height: S_3 - 2 }).fill(this.configured ? MINT : TEXT_4)
    }.width("100%").padding(S_4).borderRadius(R_LG).backgroundColor(BG_CARD).margin({ left: S_2, right: S_2 })
  }
}

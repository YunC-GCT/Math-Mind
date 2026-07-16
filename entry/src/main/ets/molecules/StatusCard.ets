// ============================================================================
//  StatusCard.ets — 连接状态卡片分子
//  ----------------------------------------------------------------------------
//  用途: 顶部连接状态条，显示模型服务是否在线
//  UI:    ┌──────────────────────────────┐
//         │ 连接状态          ● (绿/灰)  │
//         │ 已配置 · 连接正常              │
//         └──────────────────────────────┘
//  接口:
//    @Prop configured   — 是否已配置
//    @Prop statusText   — 状态文字（"已配置"/"未配置"/"连接失败"）
//    @Prop cardPadding  — 卡片内边距 (S_4)
//  依赖: common ColorTokens (MINT/TEXT/TEXT_3/TEXT_4/BG_CARD/F_XS/F_BASE/W_SEMIBOLD/R_LG)
//  对接: AiSettingsPage 的 configured/statusText 状态
// ============================================================================// ============================================================================
//  molecules/StatusCard.ets — 连接状态卡片分子
//  来源: AiSettingsPage 连接状态行
// ============================================================================

import { MINT, BG_CARD, TEXT, TEXT_3, TEXT_4, F_XS, F_BASE, W_SEMIBOLD, R_LG } from "common"

@Component
export struct StatusCard {
  @Prop configured: boolean = false
  @Prop statusText: string = "未配置"
  @Prop cardPadding: number = 16

  build() {
    Row() {
      Column() {
        Text("连接状态").fontSize(F_XS).fontColor(TEXT_3).margin({ bottom: 4 })
        Text(this.statusText).fontSize(F_BASE).fontWeight(W_SEMIBOLD)
          .fontColor(this.configured ? MINT : TEXT_4)
      }.alignItems(HorizontalAlign.Start)
      Blank()
      Circle({ width: 10, height: 10 }).fill(this.configured ? MINT : TEXT_4)
    }
    .width("100%").padding(this.cardPadding).borderRadius(R_LG).backgroundColor(BG_CARD)
  }
}

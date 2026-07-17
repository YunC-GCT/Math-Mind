// ============================================================================
//  pages/AiSettings/EndpointPicker.ets — 设置页端点选择器
//  ----------------------------------------------------------------------------
//  职责: 让用户选 DeepSeek 官方端点(默认)或填自定义 OpenAI 兼容端点。
//
//  选项:
//    [1] DeepSeek 官方 — 常量 DS_ENDPOINT
//    [2] 自定义        — 输入框(用户填完整 URL)
//
//  依赖: common 令牌(BG_CARD / TEXT / TEXT_4 / R_MD / R_LG / F_XS / F_SM)
//
//  Props:
//    useCustom:    当前是否选了自定义
//    customText:   自定义端点 URL
//    onCustomChange: 自定义端点输入回调
//    onToggle:     切换 官方/自定义 回调
//  ============================================================================

import { BG_CARD, TEXT, TEXT_4, R_MD, R_LG, F_XS, F_SM } from "common"

// DeepSeek 官方端点常量
export const DS_ENDPOINT = "https://api.deepseek.com/chat/completions"

@Component
export struct EndpointPicker {
  // 是否选了自定义端点
  @Prop useCustom: boolean = false

  // 自定义端点 URL 文本
  @Prop customText: string = ""

  // 自定义端点输入回调
  onCustomChange?: (v: string) => void = (_v: string): void => {}

  // 切换 官方/自定义 回调
  onToggle?: (custom: boolean) => void = (_custom: boolean): void => {}

  build() {
    Column() {
      // [1] DeepSeek 官方(默认)
      Row() {
        Radio({ value: "ep_ds", group: "ep" })
          .checked(!this.useCustom)
          .onChange((v: boolean): void => {
            if (v && this.onToggle) { this.onToggle(false) }
          })
        Text("DeepSeek 官方")
          .fontSize(F_SM)
          .fontColor(TEXT)
      }
      .width("100%")
      .padding({ left: 4, right: 4, top: 6, bottom: 6 })

      // [2] 自定义端点
      Row() {
        Radio({ value: "ep_c", group: "ep" })
          .checked(this.useCustom)
          .onChange((v: boolean): void => {
            if (v && this.onToggle) { this.onToggle(true) }
          })

        TextInput({ text: this.customText, placeholder: "自定义端点..." })
          .layoutWeight(1)
          .height(44)
          .fontSize(F_XS)
          .fontColor(TEXT)
          .placeholderColor(TEXT_4)
          .backgroundColor("#0AFFFFFF")
          .borderRadius(R_MD)
          .onChange((v: string): void => {
            if (this.onCustomChange) { this.onCustomChange(v) }
          })
      }
      .width("100%")
      .padding({ left: 4, right: 8, top: 6, bottom: 10 })
    }
    .width("100%")
    .borderRadius(R_LG)
    .backgroundColor(BG_CARD)
    .margin({ left: 8, right: 8 })
  }
}

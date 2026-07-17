// ============================================================================
//  pages/AiSettings/KeyInput.ets — 设置页 API Key 输入
//  ----------------------------------------------------------------------------
//  职责: 密码式 API Key 输入框 + 测试连接按钮。
//
//  布局:
//    [Password TextInput ........... ] [测试按钮]
//
//  依赖: common 令牌(MINT / BG_CARD / BG_DARK / TEXT / TEXT_4 / F_XS / F_SM / R_MD / R_LG)
//
//  Props:
//    apiKey:  当前 API Key 文本
//    testing: 是否正在测试连接(决定按钮禁用 + 显示 "...")
//    onChange: Key 输入回调
//    onTest:   测试按钮点击回调
//  ============================================================================

import { MINT, BG_CARD, BG_DARK, TEXT, TEXT_4, F_XS, F_SM, R_MD, R_LG } from "common"

@Component
export struct KeyInput {
  // 当前 API Key
  @Prop apiKey: string = ""

  // 是否正在测试连接
  @Prop testing: boolean = false

  // Key 输入回调
  onChange?: (v: string) => void = (_v: string): void => {}

  // 测试按钮点击回调
  onTest?: () => void = (): void => {}

  build() {
    Row() {
      // 密码式输入框(隐藏明文)
      TextInput({ text: this.apiKey, placeholder: "sk-..." })
        .type(InputType.Password)
        .layoutWeight(1)
        .height(42)
        .fontSize(F_SM)
        .fontColor(TEXT)
        .placeholderColor(TEXT_4)
        .backgroundColor("transparent")
        .onChange((v: string): void => {
          if (this.onChange) { this.onChange(v) }
        })

      // 测试按钮(测试中禁用,文字显示 "...")
      Button(this.testing ? "..." : "测试")
        .fontSize(F_XS)
        .fontColor(BG_DARK)
        .height(44)
        .borderRadius(R_MD)
        .backgroundColor(MINT)
        .enabled(!this.testing)
        .margin({ left: 8 })
        .onClick((): void => {
          if (this.onTest) { this.onTest() }
        })
    }
    .width("100%")
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .borderRadius(R_LG)
    .backgroundColor(BG_CARD)
    .margin({ left: 8, right: 8 })
  }
}

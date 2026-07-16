// ============================================================================
//  KeyInput.ets — API Key 输入行分子
//  ----------------------------------------------------------------------------
//  用途: API 密钥输入 + 明文/密文切换 + 连通性测试按钮
//  UI:    [👁] [sk-••••••••••••••] [测试]
//        点击 👁 → 🙈 切换明文/密文; 点击测试 → 调用 LLM 验证连接
//  接口:
//    @Prop apiKey     — 父组件 API Key 字符串
//    @Prop testing    — 是否正在测试中（按钮 loading 态）
//    onChange(v)      — Key 变更回调 → 父更新 apiKey
//    onTest           — 测试按钮回调 → 父 handleTest()
//  内部状态:
//    @State showKey   — 👁/🙈 切换
//  依赖: common ColorTokens (MINT/BG_DARK/BG_CARD/TEXT/TEXT_4/F_XS/F_SM/R_MD)
//  对接: AiSettingsPage 的 apiKey/testing/handleTest
// ============================================================================// ============================================================================
//  molecules/KeyInput.ets — API Key 输入行
//  来源: AiSettingsPage API Key 行
import { MINT, BG_DARK, BG_CARD, TEXT, TEXT_3, TEXT_4, F_XS, F_SM, R_MD, GLASS_8 } from "common"

@Component
export struct KeyInput {
  @Prop apiKey: [redacted] = ''
  @Prop testing: boolean = false
  onChange?: (v: string) => void
  onTest?: () => void

  @State showKey: boolean = false

  build() {
    Row() {
      Text(this.showKey ? "🙈" : "👁").fontSize(18).width(36).textAlign(TextAlign.Center)
        .onClick((): void => { this.showKey = !this.showKey })

      TextInput({ text: this.apiKey, placeholder: "sk-..." })
        .type(this.showKey ? InputType.Normal : InputType.Password)
        .layoutWeight(1).height(42)
        .fontSize(F_SM).fontColor(TEXT).placeholderColor(TEXT_4)
        .backgroundColor("transparent")
        .onChange((v: string): void => { if (this.onChange) { this.onChange(v) } })

      Button(this.testing ? "..." : "测试").fontSize(F_XS).fontColor(BG_DARK)
        .height(44).borderRadius(R_MD).backgroundColor(MINT)
        .enabled(!this.testing).margin({ left: 8 })
        .onClick((): void => { if (this.onTest) { this.onTest() } })
    }
    .width("100%").padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .borderRadius(12).backgroundColor(BG_CARD)
  }
}

// ============================================================================
//  molecules/KeyInput.ets — API Key 输入行
//  来源: AiSettingsPage API Key 行
// ============================================================================

import { MINT, BG_DARK, BG_CARD, TEXT, TEXT_3, TEXT_4, F_XS, F_SM, R_MD, GLASS_8 } from "common"

@Component
export struct KeyInput {
  @Link apiKey: string
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
        .onChange((v: string): void => { this.apiKey = v })

      Button(this.testing ? "..." : "测试").fontSize(F_XS).fontColor(BG_DARK)
        .height(44).borderRadius(R_MD).backgroundColor(MINT)
        .enabled(!this.testing).margin({ left: 8 })
        .onClick((): void => { if (this.onTest) { this.onTest() } })
    }
    .width("100%").padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .borderRadius(12).backgroundColor(BG_CARD)
  }
}

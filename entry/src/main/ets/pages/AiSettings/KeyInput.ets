// 设置页 · API Key 输入
import { MINT, BG_CARD, BG_DARK, TEXT, TEXT_4, F_XS, F_SM, R_MD, R_LG } from "common"
@Component
export struct KeyInput {
  @Prop apiKey: string = ""
  @Prop testing: boolean = false
  onChange?: (v: string) => void
  onTest?: () => void
  build() {
    Row() {
      TextInput({ text: this.apiKey, placeholder: "sk-..." }).type(InputType.Password)
        .layoutWeight(1).height(42).fontSize(F_SM).fontColor(TEXT).placeholderColor(TEXT_4).backgroundColor("transparent")
        .onChange((v: string): void => { if (this.onChange) { this.onChange(v) } })
      Button(this.testing ? "..." : "测试").fontSize(F_XS).fontColor(BG_DARK)
        .height(44).borderRadius(R_MD).backgroundColor(MINT).enabled(!this.testing).margin({ left: 8 })
        .onClick((): void => { if (this.onTest) { this.onTest() } })
    }.width("100%").padding({ left: 16, right: 16, top: 8, bottom: 8 }).borderRadius(R_LG).backgroundColor(BG_CARD).margin({ left: 8, right: 8 })
  }
}

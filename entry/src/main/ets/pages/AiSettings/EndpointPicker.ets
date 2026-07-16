// 设置页 · 端点选择器 (仅 DeepSeek)
import { BG_CARD, TEXT, TEXT_4, R_MD, R_LG, F_XS, F_SM } from "common"
export const DS_ENDPOINT = "https://api.deepseek.com/chat/completions"
@Component
export struct EndpointPicker {
  @Prop useCustom: boolean = false
  @Prop customText: string = ""
  onCustomChange?: (v: string) => void
  onToggle?: (custom: boolean) => void
  build() {
    Column() {
      Row() {
        Radio({ value: "ep_ds", group: "ep" }).checked(!this.useCustom)
          .onChange((v: boolean): void => { if (v && this.onToggle) { this.onToggle(false) } })
        Text("DeepSeek 官方").fontSize(F_SM).fontColor(TEXT)
      }.width("100%").padding({ left: 4, right: 4, top: 6, bottom: 6 })
      Row() {
        Radio({ value: "ep_c", group: "ep" }).checked(this.useCustom)
          .onChange((v: boolean): void => { if (v && this.onToggle) { this.onToggle(true) } })
        TextInput({ text: this.customText, placeholder: "自定义端点..." }).layoutWeight(1).height(44)
          .fontSize(F_XS).fontColor(TEXT).placeholderColor(TEXT_4)
          .backgroundColor("#0AFFFFFF").borderRadius(R_MD)
          .onChange((v: string): void => { if (this.onCustomChange) { this.onCustomChange(v) } })
      }.width("100%").padding({ left: 4, right: 8, top: 6, bottom: 10 })
    }.width("100%").borderRadius(R_LG).backgroundColor(BG_CARD).margin({ left: 8, right: 8 })
  }
}

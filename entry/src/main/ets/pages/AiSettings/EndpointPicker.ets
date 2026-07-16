// 设置页 · 端点选择器 (仅 DeepSeek)
import { BG_CARD, TEXT, TEXT_4, GLASS_8, R_MD, R_LG, F_XS, F_SM, S_1, S_2, AI_SETTINGS_BTN_H } from "common"
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
      }.width("100%").padding({ left: S_1, right: S_1, top: S_2 - 2, bottom: S_2 - 2 })
      Row() {
        Radio({ value: "ep_c", group: "ep" }).checked(this.useCustom)
          .onChange((v: boolean): void => { if (v && this.onToggle) { this.onToggle(true) } })
        TextInput({ text: this.customText, placeholder: "自定义端点..." }).layoutWeight(1).height(AI_SETTINGS_BTN_H)
          .fontSize(F_XS).fontColor(TEXT).placeholderColor(TEXT_4)
          .backgroundColor(GLASS_8).borderRadius(R_MD)
          .onChange((v: string): void => { if (this.onCustomChange) { this.onCustomChange(v) } })
      }.width("100%").padding({ left: S_1, right: S_2, top: S_2 - 2, bottom: S_3 - 2 })
    }.width("100%").borderRadius(R_LG).backgroundColor(BG_CARD).margin({ left: S_2, right: S_2 })
  }
}

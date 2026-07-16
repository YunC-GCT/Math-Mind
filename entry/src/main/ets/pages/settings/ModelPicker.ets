// 设置页 · 模型选择器 (仅 DeepSeek-V3)
import { BG_CARD, TEXT, TEXT_4, R_MD, R_LG, F_XS, F_SM } from "common"
export const DEFAULT_MODEL = "deepseek-chat"
@Component
export struct ModelPicker {
  @Prop useCustom: boolean = false
  @Prop customText: string = ""
  onCustomChange?: (v: string) => void
  onToggle?: (custom: boolean) => void
  build() {
    Column() {
      Row() {
        Radio({ value: "md_ds", group: "md" }).checked(!this.useCustom)
          .onChange((v: boolean): void => { if (v && this.onToggle) { this.onToggle(false) } })
        Column() {
          Text("DeepSeek-V3").fontSize(F_SM).fontColor(TEXT)
          Text(DEFAULT_MODEL + " · 64K").fontSize(9).fontColor(TEXT_4).margin({ top: 1 })
        }.alignItems(HorizontalAlign.Start).margin({ left: 8 })
      }.width("100%").padding({ left: 4, right: 4, top: 6, bottom: 6 })
      Row() {
        Radio({ value: "md_c", group: "md" }).checked(this.useCustom)
          .onChange((v: boolean): void => { if (v && this.onToggle) { this.onToggle(true) } })
        TextInput({ text: this.customText, placeholder: "自定义模型..." }).layoutWeight(1).height(44)
          .fontSize(F_XS).fontColor(TEXT).placeholderColor(TEXT_4)
          .backgroundColor("#0AFFFFFF").borderRadius(R_MD)
          .onChange((v: string): void => { if (this.onCustomChange) { this.onCustomChange(v) } })
      }.width("100%").padding({ left: 4, right: 8, top: 6, bottom: 10 })
    }.width("100%").borderRadius(R_LG).backgroundColor(BG_CARD).margin({ left: 8, right: 8 })
  }
}

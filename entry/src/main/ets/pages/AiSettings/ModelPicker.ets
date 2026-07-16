// 设置页 · 模型选择器 (DeepSeek V4 最新)
import { BG_CARD, TEXT, TEXT_4, R_MD, R_LG, F_XS, F_SM, W_SEMIBOLD } from "common"

export const DEFAULT_MODEL = "deepseek-v4-flash"

@Component
export struct ModelPicker {
  @Prop mdlIdx: number = 0
  @Prop useCustom: boolean = false
  @Prop customText: string = ""
  onSelect?: (idx: number) => void
  onCustomChange?: (v: string) => void
  onToggle?: (custom: boolean) => void

  build() {
    Column() {
      // V4-Flash (默认)
      Row() {
        Radio({ value: "md0", group: "md" }).checked(!this.useCustom && this.mdlIdx === 0)
          .onChange((v: boolean): void => { if (v && this.onSelect) { this.onSelect(0) } })
        Column() {
          Text("DeepSeek-V4-Flash").fontSize(F_SM).fontColor(TEXT).fontWeight(W_SEMIBOLD)
          Text("1M 上下文 · 1元/3元(输入/输出)").fontSize(9).fontColor(TEXT_4).margin({ top: 1 })
        }.alignItems(HorizontalAlign.Start).margin({ left: 8 }).layoutWeight(1)
      }.width("100%").padding({ left: 4, right: 4, top: 6, bottom: 6 })

      // V4-Pro
      Row() {
        Radio({ value: "md1", group: "md" }).checked(!this.useCustom && this.mdlIdx === 1)
          .onChange((v: boolean): void => { if (v && this.onSelect) { this.onSelect(1) } })
        Column() {
          Text("DeepSeek-V4-Pro").fontSize(F_SM).fontColor(TEXT).fontWeight(W_SEMIBOLD)
          Text("1M 上下文 · 3元/6元(输入/输出)").fontSize(9).fontColor(TEXT_4).margin({ top: 1 })
        }.alignItems(HorizontalAlign.Start).margin({ left: 8 }).layoutWeight(1)
      }.width("100%").padding({ left: 4, right: 4, top: 6, bottom: 6 })

      // 自定义
      Row() {
        Radio({ value: "md_c", group: "md" }).checked(this.useCustom)
          .onChange((v: boolean): void => { if (v && this.onToggle) { this.onToggle(true) } })
        TextInput({ text: this.customText, placeholder: "自定义模型 ID..." }).layoutWeight(1).height(44)
          .fontSize(F_XS).fontColor(TEXT).placeholderColor(TEXT_4)
          .backgroundColor("#0AFFFFFF").borderRadius(R_MD)
          .onChange((v: string): void => { if (this.onCustomChange) { this.onCustomChange(v) } })
      }.width("100%").padding({ left: 4, right: 8, top: 6, bottom: 10 })
    }.width("100%").borderRadius(R_LG).backgroundColor(BG_CARD).margin({ left: 8, right: 8 })
  }
}

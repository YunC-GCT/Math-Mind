// ============================================================================
//  pages/AiSettings/ModelPicker.ets - model selector
// ============================================================================

import { BG_CARD, TEXT, TEXT_4, R_MD, R_LG, F_XS, F_SM, W_SEMIBOLD, S_1 } from "common"

export const PRO_MODEL = "deepseek-v4-pro"

@Component
export struct ModelPicker {
  @Prop mdlIdx: number = 0
  @Prop useCustom: boolean = false
  @Prop customText: string = ""
  onSelect?: (idx: number) => void = (_idx: number): void => {}
  onCustomChange?: (v: string) => void = (_v: string): void => {}
  onToggle?: (custom: boolean) => void = (_custom: boolean): void => {}

  build() {
    Column() {
      this.OptionRow(0, "DeepSeek-V4-Pro", "复杂推理 · " + PRO_MODEL, !this.useCustom)

      Row() {
        Radio({ value: "md_c", group: "md" })
          .checked(this.useCustom)
          .onChange((v: boolean): void => {
            if (v && this.onToggle) { this.onToggle(true) }
          })

        TextInput({ text: this.customText, placeholder: "自定义 model id..." })
          .layoutWeight(1)
          .height(44)
          .fontSize(F_XS)
          .fontColor(TEXT)
          .placeholderColor(TEXT_4)
          .backgroundColor("#0AFFFFFF")
          .borderRadius(R_MD)
          .padding({ left: 10, right: 10 })
          .margin({ left: 8 })
          .onChange((v: string): void => {
            if (this.onCustomChange) { this.onCustomChange(v) }
          })
      }
      .width("100%")
      .padding({ left: 8, right: 8, top: 8, bottom: 10 })
    }
    .width("100%")
    .borderRadius(R_LG)
    .backgroundColor(BG_CARD)
    .margin({ left: 8, right: 8 })
  }

  @Builder
  OptionRow(index: number, title: string, subtitle: string, checked: boolean) {
    Row() {
      Radio({ value: "md" + index.toString(), group: "md" })
        .checked(checked)
        .onChange((v: boolean): void => {
          if (v && this.onSelect) { this.onSelect(index) }
        })

      Column() {
        Text(title)
          .fontSize(F_SM)
          .fontColor(TEXT)
          .fontWeight(W_SEMIBOLD)
        Text(subtitle)
          .fontSize(F_XS)
          .fontColor(TEXT_4)
          .margin({ top: S_1 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 8 })
      .layoutWeight(1)
    }
    .width("100%")
    .padding({ left: 8, right: 8, top: 8, bottom: 8 })
  }
}

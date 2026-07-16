// ============================================================================
//  molecules/ModelPicker.ets — 模型选择器分子
//  依赖: common token + ModelPreset 接口
//  ============================================================================

import {
  TEXT, TEXT_4,
  S_2, R_MD, R_LG,
  F_XS, F_SM,
  GLASS_8, BG_CARD,
} from "common"

export interface ModelPreset { label: string; value: string; ctx?: string; price?: string }

export const SF_MODELS: ModelPreset[] = [
  { label: "DeepSeek-V3", value: "deepseek-ai/DeepSeek-V3", ctx: "64K", price: "1/M" },
  { label: "DeepSeek-R1", value: "deepseek-ai/DeepSeek-R1", ctx: "128K", price: "4/M" },
]
export const DS_MODELS: ModelPreset[] = [
  { label: "DeepSeek-V4-Flash", value: "deepseek-v4-flash", ctx: "32K", price: "0.1/M" },
  { label: "DeepSeek-V4-Pro", value: "deepseek-v4-pro", ctx: "128K", price: "2/M" },
]

@Component
export struct ModelPicker {
  @Prop presets: ModelPreset[] = SF_MODELS
  @Prop mdlIdx: number = 0
  @Prop useCustom: boolean = false
  @Link customText: string
  onSelect?: (idx: number) => void
  onCustom?: () => void

  build() {
    Column() {
      ForEach(this.presets,
        (mp: ModelPreset, i: number): void => {
          Row() {
            Radio({ value: "md" + i, group: "md" })
              .checked(!this.useCustom && this.mdlIdx === i)
              .onChange((v: boolean): void => { if (v && this.onSelect) { this.onSelect(i) } })
            Column() {
              Text(mp.label).fontSize(F_SM).fontColor(TEXT)
              if (mp.ctx) {
                Text((mp.ctx ?? "") + " · " + (mp.price ?? ""))
                  .fontSize(9).fontColor(TEXT_4).margin({ top: 1 })
              }
            }.alignItems(HorizontalAlign.Start).margin({ left: 8 }).layoutWeight(1)
          }.width("100%").padding({ left: 4, right: 4, top: 6, bottom: 6 })
        },
        (_mp: ModelPreset, i: number): string => i.toString()
      )

      Row() {
        Radio({ value: "md_custom", group: "md" })
          .checked(this.useCustom)
          .onChange((v: boolean): void => { if (v && this.onCustom) { this.onCustom() } })
        TextInput({ text: this.customText, placeholder: "model-id" })
          .layoutWeight(1).height(44)
          .fontSize(F_XS).fontColor(TEXT).placeholderColor(TEXT_4)
          .backgroundColor(GLASS_8).borderRadius(R_MD)
          .onChange((v: string): void => { this.customText = v })
      }.width("100%").padding({ left: 4, right: 8, top: 6, bottom: 10 })
    }
    .width("100%").borderRadius(R_LG).backgroundColor(BG_CARD)
    .margin({ left: S_2, right: S_2 })
  }
}

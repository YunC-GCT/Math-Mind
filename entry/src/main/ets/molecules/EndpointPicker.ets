// ============================================================================
//  molecules/EndpointPicker.ets — 端点选择器分子
//  依赖: common token + EP_PRESETS/EP_LABELS 常量
//  ============================================================================

import {
  TEXT, TEXT_4, BORDER,
  S_2, R_MD, R_LG,
  F_XS, F_SM,
  GLASS_8, BG_CARD,
} from "common"

export const EP_PRESETS: string[] = [
  "https://api.siliconflow.cn/v1/chat/completions",
  "https://api.deepseek.com/chat/completions",
]
export const EP_LABELS: string[] = ["硅基流动", "DeepSeek 官方"]

@Component
export struct EndpointPicker {
  @Prop epIdx: number = 0
  @Prop useCustom: boolean = false
  @Prop customText: string = ''
  onTextChange?: (v: string) => void
  onSelect?: (idx: number) => void
  onCustom?: () => void

  build() {
    Column() {
      ForEach(EP_PRESETS,
        (ep: string, i: number): void => {
          Row() {
            Radio({ value: "ep" + i, group: "ep" })
              .checked(!this.useCustom && this.epIdx === i)
              .onChange((v: boolean): void => { if (v && this.onSelect) { this.onSelect(i) } })
            Column() {
              Text(EP_LABELS[i]).fontSize(F_SM).fontColor(TEXT)
              Text(ep).fontSize(10).fontColor(TEXT_4).maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }.alignItems(HorizontalAlign.Start).margin({ left: 8 }).layoutWeight(1)
          }.width("100%").padding({ left: 4, right: 4, top: 6, bottom: 6 })
        },
        (_ep: string, i: number): string => i.toString()
      )

      Row() {
        Radio({ value: "ep_custom", group: "ep" })
          .checked(this.useCustom)
          .onChange((v: boolean): void => { if (v && this.onCustom) { this.onCustom() } })
        TextInput({ text: this.customText, placeholder: "https://..." })
          .layoutWeight(1).height(44)
          .fontSize(F_XS).fontColor(TEXT).placeholderColor(TEXT_4)
          .backgroundColor(GLASS_8).borderRadius(R_MD)
          .onChange((v: string): void => { if (this.onTextChange) { this.onTextChange(v) } })
      }.width("100%").padding({ left: 4, right: 8, top: 6, bottom: 10 })
    }
    .width("100%").borderRadius(R_LG).backgroundColor(BG_CARD)
    .margin({ left: S_2, right: S_2 })
  }
}

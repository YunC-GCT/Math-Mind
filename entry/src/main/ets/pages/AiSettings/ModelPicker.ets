// ============================================================================
//  pages/AiSettings/ModelPicker.ets — 设置页模型选择器
//  ----------------------------------------------------------------------------
//  职责: 让用户选 DeepSeek V4 系列模型(默认 Flash,可选 Pro)或填自定义。
//
//  选项:
//    [0] DeepSeek-V4-Flash — 默认推荐,快速轻量
//    [1] DeepSeek-V4-Pro   — 旗舰性能,复杂推理
//    [2] 自定义            — 填 model ID
//
//  依赖: common 令牌(BG_CARD / TEXT / TEXT_4 / R_MD / R_LG / F_XS / F_SM / W_SEMIBOLD)
//
//  Props:
//    mdlIdx:       当前选中的预设模型 index(0 = Flash, 1 = Pro)
//    useCustom:    是否选了自定义
//    customText:   自定义模型 ID
//    onSelect:     选预设模型回调(idx 0 或 1)
//    onCustomChange: 自定义模型输入回调
//    onToggle:     切换 自定义 回调
//  ============================================================================

import { BG_CARD, TEXT, TEXT_4, R_MD, R_LG, F_XS, F_SM, W_SEMIBOLD } from "common"

// 默认模型(Flash — 快速便宜)
export const DEFAULT_MODEL = "deepseek-v4-flash"

@Component
export struct ModelPicker {
  // 当前选中的预设模型 index(0 = Flash, 1 = Pro)
  @Prop mdlIdx: number = 0

  // 是否选了自定义模型
  @Prop useCustom: boolean = false

  // 自定义模型 ID
  @Prop customText: string = ""

  // 选预设模型回调
  onSelect?: (idx: number) => void = (_idx: number): void => {}

  // 自定义模型输入回调
  onCustomChange?: (v: string) => void = (_v: string): void => {}

  // 切换 自定义 回调
  onToggle?: (custom: boolean) => void = (_custom: boolean): void => {}

  build() {
    Column() {
      // [0] DeepSeek-V4-Flash(默认推荐)
      Row() {
        Radio({ value: "md0", group: "md" })
          .checked(!this.useCustom && this.mdlIdx === 0)
          .onChange((v: boolean): void => {
            if (v && this.onSelect) { this.onSelect(0) }
          })

        Column() {
          Text("DeepSeek-V4-Flash")
            .fontSize(F_SM)
            .fontColor(TEXT)
            .fontWeight(W_SEMIBOLD)
          Text("快速轻量 · 默认推荐")
            .fontSize(9)
            .fontColor(TEXT_4)
            .margin({ top: 1 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 8 })
        .layoutWeight(1)
      }
      .width("100%")
      .padding({ left: 4, right: 4, top: 6, bottom: 6 })

      // [1] DeepSeek-V4-Pro(旗舰)
      Row() {
        Radio({ value: "md1", group: "md" })
          .checked(!this.useCustom && this.mdlIdx === 1)
          .onChange((v: boolean): void => {
            if (v && this.onSelect) { this.onSelect(1) }
          })

        Column() {
          Text("DeepSeek-V4-Pro")
            .fontSize(F_SM)
            .fontColor(TEXT)
            .fontWeight(W_SEMIBOLD)
          Text("旗舰性能 · 复杂推理")
            .fontSize(9)
            .fontColor(TEXT_4)
            .margin({ top: 1 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 8 })
        .layoutWeight(1)
      }
      .width("100%")
      .padding({ left: 4, right: 4, top: 6, bottom: 6 })

      // [2] 自定义模型
      Row() {
        Radio({ value: "md_c", group: "md" })
          .checked(this.useCustom)
          .onChange((v: boolean): void => {
            if (v && this.onToggle) { this.onToggle(true) }
          })

        TextInput({ text: this.customText, placeholder: "自定义模型 ID..." })
          .layoutWeight(1)
          .height(44)
          .fontSize(F_XS)
          .fontColor(TEXT)
          .placeholderColor(TEXT_4)
          .backgroundColor("#0AFFFFFF")
          .borderRadius(R_MD)
          .onChange((v: string): void => {
            if (this.onCustomChange) { this.onCustomChange(v) }
          })
      }
      .width("100%")
      .padding({ left: 4, right: 8, top: 6, bottom: 10 })
    }
    .width("100%")
    .borderRadius(R_LG)
    .backgroundColor(BG_CARD)
    .margin({ left: 8, right: 8 })
  }
}

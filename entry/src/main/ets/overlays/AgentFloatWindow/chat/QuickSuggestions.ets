// ============================================================================
//  overlays/AgentFloatWindow/chat/QuickSuggestions.ets — 推荐快捷词
//  ----------------------------------------------------------------------------
//  职责: 显示分组推荐问题,点击直接发送(不进入输入框)。
//
//  UI:
//    "推荐"
//    [分析错题] [讲解极限] [生成练习] [梳理知识]
//
//  Props:
//    onSelect: 快捷词点击回调(参数 = 快捷词文本)
//
//  依赖: common ColorTokens (PURPLE/PURPLE_LIGHT/TEXT_4)
//
//  来源: 从 AgentFloatWindow 内联代码拆出
//  ============================================================================

import { PURPLE, PURPLE_LIGHT, TEXT_4, S_2, S_3, S_4, R_FULL, F_XS, W_SEMIBOLD } from "common"

@Component
export struct QuickSuggestions {
  // 快捷词点击回调
  onSelect?: (prompt: string) => void = (_prompt: string): void => {}

  build() {
    Column() {
      // "推荐" 标签
      Text("推荐")
        .fontSize(9)
        .fontColor(TEXT_4)
        .fontWeight(W_SEMIBOLD)
        .padding({ left: S_4, top: S_2 })

      // 4 个快捷词 chip
      Row() {
        this.Chip("分析错题")
        this.Chip("讲解极限")
        this.Chip("生成练习")
        this.Chip("梳理知识")
      }
      .width("100%")
      .padding({ left: S_4, right: S_4, bottom: S_2 })
    }
    .width("100%")
  }

  // 复用 chip
  @Builder Chip(label: string) {
    Text(label)
      .fontSize(F_XS)
      .fontColor(PURPLE)
      .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
      .borderRadius(R_FULL)
      .backgroundColor(PURPLE_LIGHT)
      .margin({ right: S_2 })
      .onClick((): void => {
        if (this.onSelect) { this.onSelect(label) }
      })
  }
}

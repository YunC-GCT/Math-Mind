/**
 * ==========================================================================
 *  QuickSuggestions.ets — 推荐快捷词组件
 *  ==========================================================================
 *  职责: 显示分组推荐问题，点击直接发送。
 *
 *  UI:
 *    推荐
 *    [分析错题] [讲解极限] [生成练习] [梳理知识]
 *
 *  接口:
 *    onSelect(prompt)  — 点击快捷词回调 → 父 send(prompt)
 *
 *  依赖: common ColorTokens (PURPLE/PURPLE_LIGHT/TEXT_4)
 * ==========================================================================
 */// chat/QuickSuggestions.ets — 推荐快捷词
import { PURPLE, PURPLE_LIGHT, TEXT_4, S_2, S_3, S_4, R_FULL, F_XS, W_SEMIBOLD } from "common"
@Component
export struct QuickSuggestions {
  onSelect?: (prompt: string) => void
  build() {
    Column() {
      Text("\u63A8\u8350").fontSize(9).fontColor(TEXT_4).fontWeight(W_SEMIBOLD).padding({ left: S_4, top: S_2 })
      Row() {
        this.Chip("\u5206\u6790\u9519\u9898")
        this.Chip("\u8BB2\u89E3\u6781\u9650")
        this.Chip("\u751F\u6210\u7EC3\u4E60")
        this.Chip("\u68B3\u7406\u77E5\u8BC6")
      }.width("100%").padding({ left: S_4, right: S_4, bottom: S_2 })
    }.width("100%")
  }
  @Builder Chip(label: string) {
    Text(label).fontSize(F_XS).fontColor(PURPLE)
      .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
      .borderRadius(R_FULL).backgroundColor(PURPLE_LIGHT).margin({ right: S_2 })
      .onClick((): void => { if (this.onSelect) { this.onSelect(label) } })
  }
}

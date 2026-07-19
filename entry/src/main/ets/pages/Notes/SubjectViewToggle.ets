/**
 * SubjectViewToggle.ets — 学科入口视图切换控件
 *
 * 路径: pages/Notes/SubjectViewToggle.ets
 * 职责: 在 Notes 一级页切换学科入口的列视图/块视图。
 * 依赖: common 视觉令牌
 *
 * 数据流:
 *   NotesPage.subjectViewMode
 *     → SubjectViewToggle
 *       → onChange(mode)
 *
 * ArkTS 1.1 strict 适配:
 *   - 无 any/unknown
 *   - 无 C 风格 for
 *   - struct 内无普通方法
 */

import {
  BORDER, GLASS_8, MINT, TEXT_3,
  R_FULL,
  F_XS,
  W_SEMIBOLD,
} from "common"

@Component
export struct SubjectViewToggle {
  @Prop mode: string = "block"
  onChange: (mode: string) => void = (_mode: string): void => {}

  build() {
    Row() {
      Text("列")
        .fontSize(F_XS)
        .fontWeight(W_SEMIBOLD)
        .fontColor(this.mode === "list" ? MINT : TEXT_3)
        .height(22)
        .padding({ left: 10, right: 10 })
        .borderRadius(R_FULL)
        .backgroundColor(this.mode === "list" ? GLASS_8 : Color.Transparent)
        .onClick((): void => this.onChange("list"))

      Text("块")
        .fontSize(F_XS)
        .fontWeight(W_SEMIBOLD)
        .fontColor(this.mode === "block" ? MINT : TEXT_3)
        .height(22)
        .padding({ left: 10, right: 10 })
        .borderRadius(R_FULL)
        .backgroundColor(this.mode === "block" ? GLASS_8 : Color.Transparent)
        .onClick((): void => this.onChange("block"))
    }
    .height(28)
    .padding({ left: 2, right: 2 })
    .borderRadius(R_FULL)
    .backgroundColor(GLASS_8)
    .border({ width: 0.5, color: BORDER })
    .alignItems(VerticalAlign.Center)
  }
}

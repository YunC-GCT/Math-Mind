// ============================================================================
//  components/ConfBadge.ets — 置信度徽章原子组件
//  ----------------------------------------------------------------------------
//  职责: 展示置信度圆点 + 百分比 + 标签文字。
//  来源: 从 NoteDetailOverlay.ets ConfBadge @Builder 抽取。
//  ============================================================================

import { MINT, WARNING, DANGER, W_SEMIBOLD, DOT_SIZE, F_XS } from "common"

export function confColor(c: number): string {
  if (c > 0.8) { return MINT }
  if (c > 0.5) { return WARNING }
  return DANGER
}

function confLabel(c: number): string {
  if (c > 0.8) { return "已掌握" }
  if (c > 0.5) { return "一般" }
  return "待巩固"
}

@Component
export struct ConfBadge {
  @Prop conf: number = 0.85

  build() {
    Row() {
      Column()
        .width(DOT_SIZE - 2).height(DOT_SIZE - 2)
        .borderRadius((DOT_SIZE - 2) / 2)
        .backgroundColor(confColor(this.conf))
      Text("  ")
        .fontSize(F_XS)
      Text(Math.round(this.conf * 100) + "% " + confLabel(this.conf))
        .fontSize(F_XS)
        .fontWeight(W_SEMIBOLD)
        .fontColor(confColor(this.conf))
    }
    .alignItems(VerticalAlign.Center)
  }
}

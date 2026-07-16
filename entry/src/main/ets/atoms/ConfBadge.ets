// ============================================================================
//  components/ConfBadge.ets — 置信度徽章原子组件
//  ----------------------------------------------------------------------------
//  职责: 展示置信度圆点 + 百分比 + 标签文字。
//  来源: 从 NoteDetailOverlay.ets ConfBadge @Builder 抽取。
//  ============================================================================

import { MINT, AMBER, DANGER, F_XS } from "common"

export function confColor(c: number): string {
  if (c >= 0.85) { return MINT }
  if (c >= 0.6) { return AMBER }
  return DANGER
}

function confLabel(c: number): string {
  if (c >= 0.85) { return "已掌握" }
  if (c >= 0.6) { return "一般" }
  return "待巩固"
}

@Component
export struct ConfBadge {
  @Prop conf: number = 0.85

  build() {
    Row() {
      Column()
        .width(6).height(6)
        .borderRadius(3)
        .backgroundColor(confColor(this.conf))
      Text("  ")
        .fontSize(F_XS)
      Text(Math.round(this.conf * 100) + "% " + confLabel(this.conf))
        .fontSize(F_XS)
        .fontWeight(600)
        .fontColor(confColor(this.conf))
    }
    .alignItems(VerticalAlign.Center)
  }
}
